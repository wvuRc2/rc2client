//
//  SessionViewController.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "SessionViewController.h"
#import "Rc2AppConstants.h"
#import "RCActiveLogin.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "AMResizableSplitViewController.h"
#import "AMResizableSplitterView.h"
#import "EditorViewController.h"
#import "ConsoleViewController.h"
#import "Rc2Server.h"
#import "ImageDisplayController.h"
#import "ImageCollectionController.h"
#import "RCImage.h"
#import "RCImageCache.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCSessionUser.h"
#import "RCSavedSession.h"
#import "RCTextAttachment.h"
#import "ControlViewController.h"
#import "RCAudioChatEngine.h"
#import "DoodleViewController.h"
#import "MAKVONotificationCenter.h"
#import "RCDropboxSync.h"
#import "kTController.h"
#import "AMHudView.h"

@interface SessionViewController() <KTControllerDelegate,AMResizableSplitViewControllerDelegate,RCDropboxSyncDelegate>
@property (nonatomic, strong) IBOutlet AMResizableSplitViewController *splitController;
@property (nonatomic, strong) UIBarButtonItem *mikeButton;
@property (nonatomic, strong) UIBarButtonItem *doodleButton;
@property (nonatomic, strong) UIBarButtonItem *controlButton;
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, strong) ImageDisplayController *imgController;
@property (nonatomic, strong) ImageCollectionController *icolController;
@property (nonatomic, strong) ControlViewController *controlController;
@property (nonatomic, strong) UIPopoverController *controlPopover;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) DoodleViewController *doodle;
@property (nonatomic, strong) kTController *consoleKeyboardToolbar;
@property (weak, nonatomic, readwrite) RCSession *session;
@property (nonatomic, strong) AMHudView *currentHudView;
@property (nonatomic, assign) BOOL reconnecting;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeEvent:) name:RC2IdleTimerFiredNotification object:nil];
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
	__weak SessionViewController *bself = self;

	self.navigationItem.title = [NSString stringWithFormat:@"Workspace: %@", self.session.workspace.name];
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
	rec.origin.y += 64;
	rec.size.height -= 64;
	self.splitController.view.frame = rec;
	self.splitController.splitterPosition = splitPos;
	[self addChildViewController:self.splitController];
	[self.view addSubview:self.splitController.view];
	[self.splitController didMoveToParentViewController:self];

	self.splitController.splitterView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];

	RCSavedSession *savedState = self.session.savedSessionState;
	self.consoleController.session = self.session;
	[self.consoleController view]; //force loading
	self.consoleKeyboardToolbar = [[kTController alloc] initWithDelegate:self];
	self.consoleController.textField.inputAccessoryView = self.consoleKeyboardToolbar.inputView;
	self.editorController.session = self.session;
	[self.editorController view];
	[self.editorController restoreSessionState:savedState];
	if (self.session.initialFileSelection) {
		[self.editorController loadFile:self.session.initialFileSelection showProgress:NO];
	}
	[self.consoleController restoreSessionState:savedState];
	[self.session.workspace refreshFiles];
	if (!self.session.socketOpen)
		[self performSelector:@selector(openSessionWithProgress:) withObject:@"Connecting to server…" afterDelay:0.2];
	NSMutableArray *ritems = [self.standardRightNavBarItems mutableCopy];
	if (nil == ritems)
		ritems = [NSMutableArray array];
	self.mikeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mikeOff"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMicrophone:)];
	[ritems addObject:self.mikeButton];
	RCActiveLogin *login = [Rc2Server sharedInstance].activeLogin;
	if (login.isAdmin || [login.usersPermissions containsObject:@"CROOM_SESS"]) {
		self.doodleButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"doodle"] style:UIBarButtonItemStylePlain target:self action:@selector(showDoodleView:)];
		[ritems addObject:self.doodleButton];
	}
	[[NSNotificationCenter defaultCenter] addObserverForName:kWillDisplayGearMenu object:nil queue:nil usingBlock:^(NSNotification *note) {
		if (bself.controlPopover.isPopoverVisible)
			[bself.controlPopover dismissPopoverAnimated:YES];
	}];
	self.controlButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"users"] style:UIBarButtonItemStylePlain target:self action:@selector(showControls:)];
	[ritems addObject:self.controlButton];
	self.navigationItem.rightBarButtonItems = ritems;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	CGFloat sp = self.splitController.splitterPosition;
	[self.splitController setSplitterPosition:sp+1 animated:NO];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	CGFloat sp = self.splitController.splitterPosition;
	[self.splitController setSplitterPosition:sp-1 animated:NO];
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
	if (self.isSettingsPopoverVisible)
		[self closeSettingsPopoverAnimated:YES];
	if (nil == self.controlController) {
		self.controlController = [[ControlViewController alloc] init];
		self.controlController.preferredContentSize = self.controlController.view.frame.size;
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
	[self.editorController userWillAdjustWidth];
}

-(void)didMoveSplitter:(AMResizableSplitViewController*)controller
{
	[self.editorController userDidAdjustWidth];
}

#pragma mark - console keyboard toolbar delegate

-(BOOL)kt_enableButtonWithSelector:(SEL)sel
{
	return YES;
}

-(void)kt_insertString:(NSString *)string
{
	UITextField *tf = self.consoleController.textField;
	UITextRange *trng = tf.selectedTextRange;
	[tf replaceRange:trng withText:string];
}

-(void)kt_execute:(id)sender
{
	NSLog(@"execute");
}

-(void)kt_leftArrow:(id)sender
{
	UITextField *tf = self.consoleController.textField;
	UITextPosition *pos = tf.selectedTextRange.start;
	pos = [tf positionFromPosition:pos inDirection:UITextLayoutDirectionLeft offset:1];
	UITextRange *rng = [tf textRangeFromPosition:pos toPosition:pos];
	tf.selectedTextRange = rng;
}

-(void)kt_rightArrow:(id)sender
{
	UITextField *tf = self.consoleController.textField;
	UITextPosition *pos = tf.selectedTextRange.start;
	pos = [tf positionFromPosition:pos inDirection:UITextLayoutDirectionRight offset:1];
	UITextRange *rng = [tf textRangeFromPosition:pos toPosition:pos];
	tf.selectedTextRange = rng;
}

/*
-(void)keyboardToolbarExecute:(KeyboardToolbar*)tbar
{
	[self.consoleController.textField resignFirstResponder];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.consoleController doExecute:tbar];
	});
}
*/

#pragma mark - meat & potatoes

-(void)openSessionWithProgress:(NSString*)message
{
	AMHudView *hud = [[AMHudView alloc] init];
	self.currentHudView = hud;
	hud.mainLabelText = message;
	hud.cancelBlock = ^(AMHudView *hview) {
		[self.navigationController popViewControllerAnimated:YES];
	};
	[hud showOverView:self.view];
	RunAfterDelay(0.1, ^{
		[self.session startWebSocket];
	});
}

-(void)idleTimeEvent:(NSNotification*)note
{
	[self saveSessionState];
}

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
	[self.consoleController loadLocalFile:file];
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
	self.currentHudView = [AMHudView hudWithLabelText:[NSString stringWithFormat:@"Downloading %@…", file.name]];
	[self.currentHudView showOverView:self.view];
	[file updateContentsFromServer:^(NSInteger success) {
		[_currentHudView hide];
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
	[self.consoleController saveSessionState:savedState];
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
	if (self.currentHudView) {
		[self.currentHudView hide];
		self.currentHudView=nil;
	}
	if (!self.reconnecting)
		self.autoReconnect=YES;
	self.reconnecting=NO;
}

-(void)connectionClosed
{
	if (!_session.socketOpen && !self.reconnecting && self.autoReconnect) {
		[self openSessionWithProgress:@"Reconnecting…"];
	}
}

-(void)appendAttributedString:(NSAttributedString*)aString
{
	[self.consoleController appendAttributedString:aString];
}

-(BOOL)textAttachmentIsImage:(NSTextAttachment*)tattach
{
	return [tattach isKindOfClass:[RCImageAttachment class]];
}

-(NSTextAttachment*)textAttachmentForImageId:(NSNumber*)imgId imageUrl:(NSString*)imgUrl
{
	RCImageAttachment *tattach = [[RCImageAttachment alloc] initWithData:nil ofType:@"rc2.image"];
	tattach.image = [ImageClass imageNamed:@"graph"];
	tattach.imageId = imgId;
	tattach.imageUrl = imgUrl;
	return tattach;
}

-(NSTextAttachment*)textAttachmentForFileId:(NSNumber*)fileId name:(NSString*)fileName fileType:(Rc2FileType *)ftype
{
	NSString *iconname = ftype.iconName;
	ImageClass *fimg = iconname.length > 0 ? [ImageClass imageNamed:iconname] : nil;
	if (nil == fimg)
		fimg = [ImageClass imageNamed:@"gendoc"];
	RCFileAttachment *tattach = [[RCFileAttachment alloc] initWithData:nil ofType:@"rc2.file"];
	tattach.image = fimg;
	tattach.fileId = fileId;
	tattach.fileName = fileName;
	return tattach;
}

-(void)displayImage:(RCImage*)image fromGroup:(NSArray*)imgGroup
{
	ZAssert(0, @"method not implemented");
}

/*
-(void)displayImageWithPathOrFile:(id)fileOrPath
{
	RCImage *img=nil;
	NSArray *imgGroup=nil;
	if ([fileOrPath isKindOfClass:[RCFile class]]) {
		img = [[RCImageCache sharedInstance] loadImageFileIntoCache:fileOrPath];
	} else {
		if ([fileOrPath hasPrefix:@"/"])
			fileOrPath = [fileOrPath substringFromIndex:1];
		NSInteger idVal = [[fileOrPath lastPathComponent] stringByDeletingPathExtension];
		img = [[RCImageCache sharedInstance] loadImageIntoCache:idVal];
		if (nil == img) {
			Rc2LogWarn(@"image does not exist: %@", fileOrPath);
			return;
		}
		imgGroup = [[RCImageCache sharedInstance] groupImagesForLinkPath:fileOrPath];
	}
	
	if (nil == self.icolController) {
		self.icolController = [[ImageCollectionController alloc] init];
		self.icolController.navigationItem.title = [NSString stringWithFormat:@"%@ Images", self.session.workspace.name];
		[self.icolController view]; //force loading
	}
	if (imgGroup.count > 0) {
			self.icolController.images = imgGroup;
	} else {
		self.icolController.images = [[[RCImageCache sharedInstance] allImages] sortedArrayUsingComparator:^(RCImage *obj1, RCImage *obj2) {
			if (obj1.timestamp > obj2.timestamp)
				return (NSComparisonResult)NSOrderedAscending;
			if (obj2.timestamp > obj1.timestamp)
				return (NSComparisonResult)NSOrderedDescending;
			return [obj1.name caseInsensitiveCompare:obj2.name];
		}];
	}
	[self.navigationController pushViewController:self.icolController animated:YES];
	
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
} */

-(void)displayOutputFile:(RCFile *)file
{
	[self.consoleController loadLocalFile:file];
}

-(void)workspaceFileUpdated:(RCFile*)file deleted:(BOOL)deleted
{
	//ignore updates while syncing files, as we are making the changes
	if (nil == self.dbsync) {
		if (deleted && file.isTextFile) {
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

-(void)loadHelpItems:(NSArray*)items topic:(NSString *)helpTopic
{
	if (items)
		[self.consoleController loadHelpItems:items topic:helpTopic];
}

-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
}

-(void)handleWebSocketError:(NSError*)error
{
	if ([error.domain isEqualToString:NSPOSIXErrorDomain] && error.code == ENOTCONN)
		return;
	Rc2LogError(@"web socket error: %@", [error localizedDescription]);
	if (self.currentHudView) {
		[self.currentHudView hide];
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
		self.currentHudView=nil;
	}
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
