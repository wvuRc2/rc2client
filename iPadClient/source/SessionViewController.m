//
//  SessionViewController.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "SessionViewController.h"
#import "AppConstants.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "MGSplitViewController.h"
#import "MGSplitDividerView.h"
#import "EditorViewController.h"
#import "ConsoleViewController.h"
#import "KeyboardView.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"
#import "ImageDisplayController.h"
#import "RCImage.h"
#import "RCImageCache.h"
#import "RCFile.h"
#import "MBProgressHUD.h"
#import "RCSessionUser.h"
#import "RCSavedSession.h"
#import "ThemeEngine.h"
#import "ControlViewController.h"
#import "RCAudioChatEngine.h"
#import "DoodleViewController.h"

@interface SessionViewController() {
	RCSession *_session;
}
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, strong) ImageDisplayController *imgController;
@property (nonatomic, strong) ControlViewController *controlController;
@property (nonatomic, strong) UIPopoverController *controlPopover;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) DoodleViewController *doodle;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *doodleButton;
@property (nonatomic, strong) id themeToken;
@property (nonatomic, copy) NSString *webTmpFileDirectory;
@property (nonatomic, assign) BOOL reconnecting;
@property (nonatomic, assign) BOOL showingProgress;
@property (nonatomic, assign) BOOL autoReconnect;
-(void)saveSessionState;
-(NSString*)escapeForJS:(NSString*)str;
-(void)displayPdfFile:(RCFile*)file;
-(void)loadAndDisplayPdfFile:(RCFile*)file;
-(void)appRestored:(NSNotification*)note;
-(void)appEnteringBackground:(NSNotification*)note;
-(void)loadKeyboard;
-(void)keyboardPrefsChanged:(NSNotification*)note;
@end

#pragma mark -

@implementation SessionViewController

-(id)initWithSession:(RCSession*)session
{
	self = [super initWithNibName:@"SessionViewController" bundle:nil];
	if (self) {
		_session = session;
		_session.delegate = self;
		NSError *err=nil;
		self.autoReconnect=NO;
		self.audioEngine = [[RCAudioChatEngine alloc] init];
		self.audioEngine.session = session;
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appRestored:) 
													 name: UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteringBackground:) 
													 name: UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardPrefsChanged:) 
													 name: KeyboardPrefsChangedNotification object:nil];
	}
	return self;
}

-(void)freeMemory
{
	self.audioEngine=nil;
	self.themeToken=nil;
	self.jsQuiteRExp=nil;
	self.imgController=nil;
	self.editorController=nil;
	self.consoleController=nil;
}

- (void)dealloc
{
	self.session.delegate=nil;
	[self freeMemory];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self loadKeyboard];
	self.titleLabel.text = self.session.workspace.name;
	CGFloat splitPos = [[_session settingForKey:@"splitPosition"] floatValue];
	if (splitPos < 300 || splitPos > 1024)
		splitPos = 512;
	
	// Calc splitViewController's view's frame:
	CGRect rec = self.view.bounds;
	rec.origin.y += 44;
	rec.size.height -= 44;
	self.splitController.view.frame = rec;
	self.splitController.showsMasterInPortrait = YES;
	self.splitController.splitPosition = splitPos;
	self.splitController.allowsDraggingDivider = YES;
	self.splitController.dividerStyle = MGSplitViewDividerStylePaneSplitter;
	self.splitController.delegate = self;
	[self.view addSubview:self.splitController.view];
	RunAfterDelay(0.4, ^{
		self.splitController.vertical = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
		[self.splitController layoutSubviewsForInterfaceOrientation:TheApp.statusBarOrientation withAnimation:NO];
	});
	
	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	self.splitController.dividerView.lightColor = [theme colorForKey:@"SessionPaneSplitterStart"];
	self.splitController.dividerView.darkColor = [theme colorForKey:@"SessionPaneSplitterEnd"];
	__weak SessionViewController *blockSelf = self;
	id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *aTheme) {
		blockSelf.splitController.dividerView.lightColor = [aTheme colorForKey:@"SessionPaneSplitterStart"];
		blockSelf.splitController.dividerView.darkColor = [aTheme colorForKey:@"SessionPaneSplitterEnd"];
	}];
	self.themeToken = tn;
	[self.splitController.dividerView addShineLayer:self.splitController.dividerView.layer 
											 bounds:self.splitController.dividerView.bounds];
	
	RCSavedSession *savedState = self.session.savedSessionState;
	self.consoleController.session = self.session;
	[self.consoleController view]; //force loading
	self.editorController.session = self.session;
	[self.editorController view];
	[self.editorController restoreSessionState:savedState];
	if (self.session.initialFileSelection) {
NSLog(@"session loading initial file:%@", self.session.initialFileSelection.name);
		[self.editorController loadFile:self.session.initialFileSelection showProgress:NO];
	}
	[self.consoleController restoreSessionState:savedState];
	[[RCImageCache sharedInstance] cacheImagesReferencedInHTML:savedState.consoleHtml];
	[self.session.workspace refreshFiles];
	if (!self.session.socketOpen) {
		RunAfterDelay(0.2, ^{
			MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
			hud.labelText = @"Connecting to server…";
			self.showingProgress = YES;
			RunAfterDelay(0.1, ^{
				[self.session startWebSocket];
			});
		});
	}
	if (![[[Rc2Server sharedInstance] usersPermissions] containsObject:@"CROOM_SESS"]) {
		NSArray *a = self.toolbar.items;
		a = [a arrayByRemovingObjectAtIndex:[a indexOfObject:self.doodleButton]];
		[self.toolbar setItems:a animated:NO];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self freeMemory];
}

#pragma mark - orientations & rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
    // Return YES for supported orientations
//    return UIInterfaceOrientationIsLandscape(ior);
	return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.splitController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//FIXME: the interface rotation would look better if done here, but the split controller some how looses
	// the splitter. until I muck around with that code, it just won't look so great.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)oldOrient
{
	[self.splitController didRotateFromInterfaceOrientation:oldOrient];	
//	UIInterfaceOrientation curOrient = [TheApp statusBarOrientation];
//	if (curOrient != oldOrient && curOrient != UIDeviceOrientationUnknown) {
//		[self.splitController toggleSplitOrientation:self];
//		self.keyboardView.isLandscape = UIDeviceOrientationIsLandscape(curOrient);
//	}
//	[self.splitController.view setNeedsLayout];
	self.splitController.vertical = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
	[self.splitController layoutSubviewsForInterfaceOrientation:TheApp.statusBarOrientation withAnimation:NO];
	[self.keyboardView setIsLandscape:UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation)];
}

#pragma mark - actions

-(IBAction)showDoodleView:(id)sender
{
	if (nil == self.doodle) {
		self.doodle = [[DoodleViewController alloc] init];
	}
	if (self.doodle.view.superview == nil) {
		[self.view addSubview:self.doodle.view];
	} else {
		[self.doodle.view removeFromSuperview];
	}
}

-(IBAction)showControls:(id)sender
{
	if (nil == self.controlController) {
		self.controlController = [[ControlViewController alloc] init];
		self.controlController.contentSizeForViewInPopover = self.controlController.view.frame.size;
		self.controlController.session = self.session;
		self.controlPopover = [[UIPopoverController alloc] initWithContentViewController:self.controlController];
	}
	if (self.controlController.view.window)
		[self.controlPopover dismissPopoverAnimated:YES];
	else
		[self.controlPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)toggleMicrophone:(id)sender
{
	if (self.audioEngine.mikeOn) {
		[self.mikeButton setImage:[UIImage imageNamed:@"mikeOff"]];
	} else {
		[self.mikeButton setImage:[UIImage imageNamed:@"mike"]];
	}
	[self.audioEngine toggleMicrophone];
}

#pragma mark - meat & potatoes

-(void)loadKeyboard
{
	//remove existing keyboard
	[self.keyboardView removeFromSuperview];
	[[NSBundle mainBundle] loadNibNamed:@"Keyboard" owner:self options:nil];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:kPrefLefty])
		self.keyboardView.keyboardStyle = eKeyboardStyle_LeftHanded;
	[self.keyboardView layoutKeyboard];
	[self.editorController setInputView:self.keyboardView];
	self.keyboardView.delegate = self.editorController;
	self.keyboardView.executeDelegate = self;
	self.keyboardView.consoleField = self.consoleController.textField;
	self.consoleController.textField.inputView = self.keyboardView;
}

-(void)handleKeyCode:(unichar)code
{
	if ([self.editorController isEditorFirstResponder])
		[self.editorController handleKeyCode:code];
	else if ([self.consoleController.textField isFirstResponder]) {
		switch (code) {
			case 0xeaa0: //execute
				[self.consoleController.textField resignFirstResponder];
				[self.consoleController doExecute:self];
				break;
		}
	}
}

-(NSString*)escapeForJS:(NSString*)str
{
	if ([str isKindOfClass:[NSString class]]) {
		str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		return [str stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	}
//		return [self.jsQuiteRExp stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) 
//													 withTemplate:@"\\'"];
	return [str description];
}

-(void)displayPdfFile:(RCFile*)file
{
	//display in document controller
	UIDocumentInteractionController *dic = [UIDocumentInteractionController interactionControllerWithURL:
											[NSURL fileURLWithPath:[file fileContentsPath]]];
	dic.delegate = (id)self;
	[dic presentPreviewAnimated:YES];	
}

-(void)loadAndDisplayPdfFile:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	//figure out where file should be stored
	NSString *path = [file fileContentsPath];
	NSURL *url = [NSURL fileURLWithPath:path];
	if ([fm fileExistsAtPath:path]) {
		NSError *err=nil;
		//the file exists. we need to compare last mod date
		NSDate *lastMod = [[fm attributesOfItemAtPath:path error:&err] fileModificationDate];
		if (lastMod)
		{
			if ([lastMod timeIntervalSinceReferenceDate] > [file.lastModified timeIntervalSinceReferenceDate])
			{
				//ok to use it
				[self displayPdfFile:file];
				return;
			}
		}
		[fm removeItemAtURL:url error:nil];
		return;
	}
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.labelText = [NSString stringWithFormat:@"Downloading %@…", file.name];
	self.showingProgress = YES;
	hud.mode = MBProgressHUDModeDeterminate;
	
	[[Rc2Server sharedInstance] fetchBinaryFileContents:file toPath:path progress:[hud valueForKey:@"indicator"]
									  completionHandler:^(BOOL success, id results) 
	{
		[MBProgressHUD hideHUDForView:self.view animated:NO];
		if (success)
			[self displayPdfFile:file];
	}];
}

-(IBAction)endSession:(id)sender
{
	if (self.controlPopover.popoverVisible)
		[self.controlPopover dismissPopoverAnimated:YES];
	[_session setSetting:[NSNumber numberWithFloat:self.splitController.splitPosition] forKey:@"splitPosition"];
	self.autoReconnect=NO;
	[_session closeWebSocket];
	[self saveSessionState];
	if (self.webTmpFileDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:self.webTmpFileDirectory error:nil];
		self.webTmpFileDirectory=nil;
	}
	[(id)[UIApplication sharedApplication].delegate endSession:sender];
}

// adds ".txt" on to the end and copies to a tmp directory that will be cleaned up later
-(NSString*)webTmpFilePath:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (nil == self.webTmpFileDirectory) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		[fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *newPath = [[self.webTmpFileDirectory stringByAppendingPathComponent:file.name] stringByAppendingPathExtension:@"txt"];
	NSError *err=nil;
	if ([fm fileExistsAtPath:newPath])
		[fm removeItemAtPath:newPath error:nil];
	if (![fm fileExistsAtPath:file.fileContentsPath]) {
		NSString *fileContents = [[Rc2Server sharedInstance] fetchFileContentsSynchronously:file];
		if (![fileContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
			Rc2LogError(@"failed to write web tmp file:%@", err);
	} else if (![fm copyItemAtPath:file.fileContentsPath toPath:newPath error:&err]) {
		Rc2LogError(@"error copying file:%@", err);
	}
	return newPath;
}

#pragma mark - state management

-(void)saveSessionState
{
	RCSavedSession *savedState = _session.savedSessionState;
	savedState.consoleHtml = [self.consoleController evaluateJavaScript:@"$('#consoleOutputGenerated').html()"];
	savedState.currentFile = self.editorController.currentFile;
	if (nil == savedState.currentFile)
		savedState.inputText = [self.editorController keyboardWantsContentString]; //FIXME: hack. need better way
}

-(void)appRestored:(NSNotification*)note
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentSessionWspaceId"];
}

-(void)appEnteringBackground:(NSNotification*)note
{
	[self saveSessionState];
	[[NSUserDefaults standardUserDefaults] setObject:_session.workspace.wspaceId forKey:@"currentSessionWspaceId"];
}

-(void)keyboardPrefsChanged:(NSNotification*)note
{
	[self loadKeyboard];
}

#pragma mark - session delegate

-(void)connectionOpened
{
	if (self.showingProgress) {
		[MBProgressHUD hideHUDForView:self.view animated:YES];
	}
	if (!self.reconnecting)
		self.autoReconnect=YES;
	self.reconnecting=NO;
}

-(void)connectionClosed
{
	if (!_session.socketOpen && !self.reconnecting && self.autoReconnect) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		hud.labelText = @"Reconnecting…";
		self.reconnecting=YES;
		self.showingProgress=YES;
		[self.session startWebSocket];
	}
}

-(void)performConsoleAction:(NSString*)action
{
	action = [action stringbyRemovingPercentEscapes];
	NSString *cmd = [NSString stringWithFormat:@"iR.appendConsoleText('%@')", action];
	[self.consoleController evaluateJavaScript:cmd];
}

-(void)displayImage:(NSString *)imgPath
{
	[self displayImageWithPathOrFile:imgPath];
}

-(void)displayImageWithPathOrFile:(id)fileOrPath
{
	RCImage *img=nil;
	if ([fileOrPath isKindOfClass:[RCFile class]]) {
		img = [[RCImageCache sharedInstance] loadImageFileIntoCache:fileOrPath];
	} else {
		if ([fileOrPath hasPrefix:@"/"])
			fileOrPath = [fileOrPath substringFromIndex:1];
		
		img = [[RCImageCache sharedInstance] loadImageIntoCache:fileOrPath];
		if (nil == img) {
			//FIXME: display alert
			Rc2LogWarn(@"image does not exist: %@", fileOrPath);
			return;
		}
	}
	
	if (nil == self.imgController)
		self.imgController = [[ImageDisplayController alloc] init];
	self.imgController.allImages = [[[RCImageCache sharedInstance] allImages] sortedArrayUsingComparator:^(RCImage *obj1, RCImage *obj2) {
		if (obj1.timestamp > obj2.timestamp)
			return NSOrderedAscending;
		if (obj2.timestamp > obj1.timestamp)
			return NSOrderedDescending;
		return [obj1.name caseInsensitiveCompare:obj2.name];
	}];
	__unsafe_unretained SessionViewController *blockSelf = self;
	self.imgController.closeHandler = ^{
		[blockSelf dismissModalViewControllerAnimated:YES];
	};
	[self presentModalViewController:self.imgController animated:YES];
	[self.imgController loadImages];
	[self.imgController loadImage1:img];
}

-(void)displayLinkedFile:(NSString*)urlPath
{
	NSString *fileIdStr = urlPath.lastPathComponent.stringByDeletingPathExtension;
	if ([urlPath hasSuffix:@".pdf"]) {
		//we want to show the pdf
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[fileIdStr integerValue]]];
		if (file.contentsLoaded)
			[self displayPdfFile:file];
		else
			[self loadAndDisplayPdfFile:file];
		return;
	}
	//a sas file most likely
	NSString *filename = urlPath.lastPathComponent;
	NSString *fileExt = filename.pathExtension;
	//what to do? see if it is an acceptable text file suffix. If so, have webview display it
	if ([[Rc2Server acceptableTextFileSuffixes] containsObject:fileExt]) {
		NSInteger fid = [[filename stringByDeletingPathExtension] integerValue];
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:fid]];
		if (file) {
			NSString *tmpPath = [self webTmpFilePath:file];
			[self.consoleController loadLocalFileURL:[NSURL fileURLWithPath:tmpPath]];
		}
	} else if ([[Rc2Server acceptableImageFileSuffixes] containsObject:fileExt]) {
		//show as an image
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[fileIdStr integerValue]]];
		if (file) {
			if (!file.contentsLoaded)
				[[Rc2Server sharedInstance] fetchBinaryFileContentsSynchronously:file];
			[self displayImageWithPathOrFile:file];
		}
	}
}

-(void)workspaceFileUpdated:(RCFile*)file
{
	if (file.fileId.intValue == self.editorController.currentFile.fileId.intValue) {
		[self.editorController loadFile:file];
	}
}

-(void)displayEditorFile:(RCFile*)file
{
	[self.editorController loadFile:file];
}

-(void)processBinaryMessage:(NSData*)data
{
	[self.audioEngine processBinaryMessage:data];
}


-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
	NSString *cmd = [dict objectForKey:@"msg"];
	NSString *js=nil;
//	Rc2LogInfo(@"processing ws command: %@", cmd);
	if ([cmd isEqualToString:@"userid"]) {
		js = [NSString stringWithFormat:@"iR.setUserid(%@)", [dict objectForKey:@"userid"]];
		if (!self.session.currentUser.master) {
			//remove control item from toolbar
			NSMutableArray *items = [self.toolbar.items mutableCopy];
			[items removeObject:self.controlButton];
			[self.toolbar setItems:items];
		}
	} else if ([cmd isEqualToString:@"echo"]) {
		js = [NSString stringWithFormat:@"iR.echoInput('%@', '%@', %@)", 
			  	[self escapeForJS:[dict objectForKey:@"script"]],
			  [self escapeForJS:[dict objectForKey:@"username"]],
			  [self escapeForJS:[dict objectForKey:@"user"]]];
	} else if ([cmd isEqualToString:@"error"]) {
		NSString *errmsg = [[dict objectForKey:@"error"] stringByTrimmingWhitespace];
		errmsg = [self escapeForJS:errmsg];
		if ([errmsg indexOf:@"\n"] > 0) {
			errmsg = [errmsg stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			js = [NSString stringWithFormat:@"iR.displayFormattedError('%@')", errmsg];
		} else {
			js = [NSString stringWithFormat:@"iR.displayError('%@')", errmsg];
		}
	} else if ([cmd isEqualToString:@"join"]) {
		js = [NSString stringWithFormat:@"iR.userJoinedSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"left"]) {
		js = [NSString stringWithFormat:@"iR.userLeftSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpPath = [dict objectForKey:@"helpPath"];
			NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://rc2.stat.wvu.edu/Rdocs/%@.html", helpPath]];
			js = [NSString stringWithFormat:@"iR.appendHelpCommand('%@', '%@')", 
				  [self escapeForJS:[dict objectForKey:@"helpTopic"]],
				  [self escapeForJS:helpUrl.absoluteString]];
			[self.consoleController loadHelpURL:helpUrl];
		} else if ([dict objectForKey:@"complexResults"]) {
			js = [NSString stringWithFormat:@"iR.appendComplexResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"json"]) {
			js = [NSString stringWithFormat:@"iR.appendResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		}
		if ([[dict objectForKey:@"imageUrls"] count] > 0) {
			NSArray *adjustedImages = [[RCImageCache sharedInstance] adjustImageArray:[dict objectForKey:@"imageUrls"]];
			js = [NSString stringWithFormat:@"iR.appendImages(%@)",
				  [adjustedImages JSONRepresentation]];
		}
	} else if ([cmd isEqualToString:@"sasoutput"]) {
		NSArray *fileInfo = [dict objectForKey:@"files"];
		for (NSDictionary *fd in fileInfo) {
			[self.session.workspace updateFileId:[fd objectForKey:@"fileId"]];
		}
		js = [NSString stringWithFormat:@"iR.appendSasFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
	} else if ([cmd isEqualToString:@"chat"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kChatMessageNotification object:nil 
														  userInfo:dict];
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		NSNumber *fileid = [dict objectForKey:@"fileId"];
		js = [NSString stringWithFormat:@"iR.appendPdf('%@', %@, '%@')", [self escapeForJS:[dict objectForKey:@"pdfurl"]], fileid,
			  [self escapeForJS:[dict objectForKey:@"filename"]]];
		[self.session.workspace updateFileId:fileid];
	}
	if (js) {
		[self.consoleController evaluateJavaScript:js];
		[self.consoleController evaluateJavaScript:@"scroll(0,document.body.scrollHeight)"];
	}
}

-(void)handleWebSocketError:(NSError*)error
{
	Rc2LogError(@"web socket error: %@", [error localizedDescription]);
	if (self.showingProgress) {
		[MBProgressHUD hideHUDForView:self.view animated:NO];
		NSString *msg = @"Failed to connect to server";
		if (self.reconnecting) {
			msg = @"Failed to reconnect to server";
			self.reconnecting=NO;
			self.autoReconnect=NO;
		}
		//error connecting
		RunAfterDelay(0.5, ^{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil 
												  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[alert showWithCompletionHandler: ^(UIAlertView *av, NSInteger idx) {
				[(id)[UIApplication sharedApplication].delegate endSession:nil];
			}];
		});
	}
	self.showingProgress=NO;
}

#pragma mark - misc

-(void)didReceiveMemoryWarning
{
	Rc2LogWarn(@"%@: memory warning", THIS_FILE);
}

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller
{
	return self;
}

- (float)splitViewController:(MGSplitViewController *)svc constrainSplitPosition:(float)proposedPosition 
			   splitViewSize:(CGSize)viewSize;
{
	BOOL isLandscape = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
	CGFloat maxSize = isLandscape ? viewSize.width : viewSize.height;
	if (maxSize - proposedPosition < 150)
		return maxSize-150;
	if (maxSize - proposedPosition < 70) {
		if (!UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation))
			return maxSize - 70;
		//need to hide toolbar
		self.consoleController.toolbar.hidden=YES;
	} else {
		//need to show the toolbar again
		self.consoleController.toolbar.hidden=NO;
	}
	if (proposedPosition > maxSize-10)
		return maxSize-10;
	if (isLandscape) {
		if (proposedPosition < 320)
			proposedPosition = 320;
	} else {
		if (proposedPosition < 200)
			return 200;
	}
	return proposedPosition;
}

#pragma mark - accessors

-(RCSession*)session 
{
	return _session;
}

@synthesize titleLabel;
@synthesize button1;
@synthesize keyboardView;
@synthesize splitController;
@synthesize editorController;
@synthesize consoleController;
@synthesize jsQuiteRExp;
@synthesize imgController;
@synthesize reconnecting;
@synthesize autoReconnect;
@synthesize bottomController;
@synthesize themeToken;
@synthesize showingProgress;
@synthesize controlButton;
@synthesize toolbar;
@synthesize controlPopover;
@synthesize controlController;
@synthesize mikeButton;
@synthesize audioEngine;
@synthesize doodle;
@synthesize doodleButton;
@synthesize webTmpFileDirectory=_webTmpFileDirectory;
@end
