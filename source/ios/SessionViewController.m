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
#import "AMResizableSplitViewController.h"
#import "AMResizableSplitterView.h"
#import "EditorViewController.h"
#import "ConsoleViewController.h"
#import "KeyboardToolbar.h"
#import "Rc2Server.h"
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
#import "MAKVONotificationCenter.h"
#import "RCDropboxSync.h"

@interface SessionViewController() <KeyboardToolbarDelegate,AMResizableSplitViewControllerDelegate,RCDropboxSyncDelegate>
@property (nonatomic, strong) IBOutlet AMResizableSplitViewController *splitController;
@property (nonatomic, strong) UIBarButtonItem *mikeButton;
@property (nonatomic, strong) UIBarButtonItem *doodleButton;
@property (nonatomic, strong) UIBarButtonItem *controlButton;
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, strong) ImageDisplayController *imgController;
@property (nonatomic, strong) ControlViewController *controlController;
@property (nonatomic, strong) UIPopoverController *controlPopover;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) DoodleViewController *doodle;
@property (nonatomic, strong) KeyboardToolbar *consoleKeyboardToolbar;
@property (nonatomic, copy) NSString *webTmpFileDirectory;
@property (weak, nonatomic, readwrite) RCSession *session;
@property (nonatomic, assign) BOOL reconnecting;
@property (nonatomic, assign) BOOL showingProgress;
@property (nonatomic, assign) BOOL autoReconnect;
@property (nonatomic, strong) RCDropboxSync *dbsync;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDropboxSync:) name:kDropboxSyncRequestedNotification object:nil];
		[self observeTarget:[Rc2Server sharedInstance] keyPath:@"loggedIn" selector:@selector(loginStatusChanged:) userInfo:nil options:0];
	}
	return self;
}

- (void)dealloc
{
	self.session.delegate=nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.title = self.session.workspace.name;
	CGFloat splitPos = [[_session settingForKey:@"splitPosition"] floatValue];
	if (splitPos < 300 || splitPos > 1024)
		splitPos = 512;
	
	self.splitController = [[AMResizableSplitViewController alloc] init];
	self.splitController.delegate = self;
	self.splitController.controller1 = self.editorController;
	self.splitController.controller2 = self.consoleController;
	self.splitController.minimumView1Size = CGSizeMake(240, 240);
	self.splitController.minimumView2Size = CGSizeMake(240, 240);
	// Calc splitViewController's view's frame:
	CGRect rec = self.view.bounds;
	rec.origin.y += 44;
	rec.size.height -= 44;
	self.splitController.view.frame = rec;
	self.splitController.splitterPosition = splitPos;
	[self addChildViewController:self.splitController];
	[self.view addSubview:self.splitController.view];
	[self.splitController didMoveToParentViewController:self];

	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	self.splitController.splitterView.backgroundColor = [theme colorForKey:@"SessionPaneSplitterStart"];
	__weak SessionViewController *blockSelf = self;
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *aTheme) {
		blockSelf.splitController.splitterView.backgroundColor = [aTheme colorForKey:@"SessionPaneSplitterStart"];
	}];

	RCSavedSession *savedState = self.session.savedSessionState;
	self.consoleController.session = self.session;
	[self.consoleController view]; //force loading
	self.consoleKeyboardToolbar = [[KeyboardToolbar alloc] init];
	self.consoleController.textField.inputAccessoryView = self.consoleKeyboardToolbar.view;
	self.consoleKeyboardToolbar.delegate = self;
	self.editorController.session = self.session;
	[self.editorController view];
	[self.editorController restoreSessionState:savedState];
	if (self.session.initialFileSelection) {
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
	Rc2Server *server = [Rc2Server sharedInstance];
	NSMutableArray *ritems = [self.standardRightNavBarItems mutableCopy];
	if (nil == ritems)
		ritems = [NSMutableArray array];
	self.mikeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mikeOff"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMicrophone:)];
	[ritems addObject:self.mikeButton];
	if ([server isAdmin] || [[server usersPermissions] containsObject:@"CROOM_SESS"]) {
		self.doodleButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"doodle"] style:UIBarButtonItemStylePlain target:self action:@selector(showDoodleView:)];
		[ritems addObject:self.doodleButton];
	}
	self.controlButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"controller"] style:UIBarButtonItemStylePlain target:self action:@selector(showControls:)];
	[ritems addObject:self.controlButton];
	self.navigationItem.rightBarButtonItems = ritems;
}

#pragma mark - orientations & rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
	return YES;
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

#pragma mark - split view delegate

-(void)willMoveSplitter:(AMResizableSplitViewController*)controller
{
	if ([self.editorController isEditorFirstResponder])
		[self.editorController editorResignFirstResponder];
}

#pragma mark - console keyboard toolbar delegate

-(void)keyboardToolbar:(KeyboardToolbar*)tbar insertString:(NSString*)str
{
	UITextField *tf = self.consoleController.textField;
	UITextRange *trng = tf.selectedTextRange;
	[tf replaceRange:trng withText:str];
}

-(void)keyboardToolbarExecute:(KeyboardToolbar*)tbar
{
	[self.consoleController.textField resignFirstResponder];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.consoleController doExecute:tbar];
	});
}


#pragma mark - meat & potatoes

-(void)handleKeyCode:(unichar)code
{
	if ([self.consoleController.textField isFirstResponder]) {
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
//	UIDocumentInteractionController *dic = [UIDocumentInteractionController interactionControllerWithURL:
//											[NSURL fileURLWithPath:[file fileContentsPath]]];
//	dic.delegate = (id)self;
//	[dic presentPreviewAnimated:YES];
	NSURL *url = [NSURL fileURLWithPath:file.fileContentsPath];
	[self.consoleController loadLocalFileURL:url];
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
	[file updateContentsFromServer:^(NSInteger success) {
		[MBProgressHUD hideHUDForView:self.view animated:NO];
		if (success)
			[self displayPdfFile:file];
	}];
}

-(void)loginStatusChanged:(MAKVONotification*)note
{
	if (![[Rc2Server sharedInstance] loggedIn])
		[(id)TheApp.delegate endSession];
}

-(void)endSession
{
	if (self.controlPopover.popoverVisible)
		[self.controlPopover dismissPopoverAnimated:YES];
	[_session setSetting:[NSNumber numberWithFloat:self.splitController.splitterPosition] forKey:@"splitPosition"];
	self.autoReconnect=NO;
	[_session closeWebSocket];
	[self saveSessionState];
	if (self.webTmpFileDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:self.webTmpFileDirectory error:nil];
		self.webTmpFileDirectory=nil;
	}
}

// adds ".txt" on to the end and copies to a tmp directory that will be cleaned up later
-(NSString*)webTmpFilePath:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (nil == self.webTmpFileDirectory) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		[fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *ext = @"txt";
	if (NSOrderedSame == [file.name.pathExtension caseInsensitiveCompare:@"html"])
		ext = @"html";
	NSString *newPath = [[self.webTmpFileDirectory stringByAppendingPathComponent:file.name] stringByAppendingPathExtension:ext];
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

///called when settings are to be displayed to get workspace to show settings for
-(RCWorkspace*)workspaceForSettings
{
	return self.session.workspace;
}

#pragma mark - dropbox sync

-(void)handleDropboxSync:(NSNotification*)note
{
	self.dbsync = [[RCDropboxSync alloc] initWithWorkspace:self.session.workspace];
	[self.dbsync startSync];
}

-(void)dbsync:(RCDropboxSync*)sync updateProgress:(CGFloat)percent message:(NSString*)message
{
	
}

-(void)dbsync:(RCDropboxSync*)sync syncComplete:(BOOL)success error:(NSError*)error
{
	self.dbsync = nil;
	if (!success) {
		Rc2LogError(@"error on sync:%@", error.localizedDescription);
	} else {
		Rc2LogInfo(@"sync complete");
	}
}


#pragma mark - state management

-(void)saveSessionState
{
	RCSavedSession *savedState = _session.savedSessionState;
	savedState.consoleHtml = [self.consoleController evaluateJavaScript:@"$('#consoleOutputGenerated').html()"];
	savedState.currentFile = self.editorController.currentFile;
	if (nil == savedState.currentFile)
		savedState.inputText = [self.editorController editorContents];
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
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.session startWebSocket];
		});
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
	NSArray *imgGroup=nil;
	if ([fileOrPath isKindOfClass:[RCFile class]]) {
		img = [[RCImageCache sharedInstance] loadImageFileIntoCache:fileOrPath];
	} else {
		if ([fileOrPath hasPrefix:@"/"])
			fileOrPath = [fileOrPath substringFromIndex:1];
		
		img = [[RCImageCache sharedInstance] loadImageIntoCache:fileOrPath];
		if (nil == img) {
			Rc2LogWarn(@"image does not exist: %@", fileOrPath);
			return;
		}
		imgGroup = [[RCImageCache sharedInstance] groupImagesForLinkPath:fileOrPath];
	}
	
	if (nil == self.imgController) {
		self.imgController = [[ImageDisplayController alloc] init];
		self.imgController.navigationItem.title = [NSString stringWithFormat:@"%@ Images", self.session.workspace.name];
		[self.imgController view]; //force loading
	}
	if (imgGroup.count > 0) {
			self.imgController.allImages = imgGroup;
	} else {
		self.imgController.allImages = [[[RCImageCache sharedInstance] allImages] sortedArrayUsingComparator:^(RCImage *obj1, RCImage *obj2) {
			if (obj1.timestamp > obj2.timestamp)
				return (NSComparisonResult)NSOrderedAscending;
			if (obj2.timestamp > obj1.timestamp)
				return (NSComparisonResult)NSOrderedDescending;
			return [obj1.name caseInsensitiveCompare:obj2.name];
		}];
	}
	[self.imgController loadImages];
	if (imgGroup)
		[self.imgController setImageDisplayCount:imgGroup.count];
	[self.navigationController pushViewController:self.imgController animated:YES];
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

-(void)workspaceFileUpdated:(RCFile*)file deleted:(BOOL)deleted
{
	//ignore updates while syncing files, as we are making the changes
	if (nil == self.dbsync) {
		if (deleted) {
			[self.editorController reloadFileData];
			[self.editorController loadFile:self.session.workspace.files.firstObject];
		} else if (file.fileId.intValue == self.editorController.currentFile.fileId.intValue) {
			[self.editorController loadFile:file];
		}
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

-(void)variablesUpdated
{
	[self.consoleController variablesUpdated];
}

-(NSString*)executeJavascript:(NSString*)js
{
	[self.consoleController evaluateJavaScript:js];
	return [self.consoleController evaluateJavaScript:@"scroll(0,document.body.scrollHeight)"];
}

-(void)loadHelpURL:(NSURL*)url
{
	[self.consoleController loadHelpURL:url];
}

-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
}

-(void)handleWebSocketError:(NSError*)error
{
	if ([error.domain isEqualToString:NSPOSIXErrorDomain] && error.code == ENOTCONN)
		return;
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
				[(id)[UIApplication sharedApplication].delegate endSession];
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


@end
