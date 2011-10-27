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
#import "NSObject+SBJSON.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"
#import "ImageDisplayController.h"
#import "RCImage.h"
#import "RCFile.h"
#import "MBProgressHUD.h"
#import "RCSavedSession.h"
#import "ThemeEngine.h"

@interface SessionViewController() {
	RCSession *_session;
}
@property (nonatomic, retain) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, retain) NSString *imgCachePath;
@property (nonatomic, retain) NSOperationQueue *dloadQueue;
@property (nonatomic, retain) NSMutableDictionary *imgCache;
@property (nonatomic, retain) ImageDisplayController *imgController;
@property (nonatomic, retain) id themeToken;
@property (nonatomic, assign) BOOL reconnecting;
@property (nonatomic, assign) BOOL showingProgress;
@property (nonatomic, assign) BOOL autoReconnect;
-(void)saveSessionState;
-(NSString*)escapeForJS:(NSString*)str;
-(NSArray*)adjustImageArray:(NSArray*)inArray;
-(void)cacheImages:(NSArray*)urls;
-(void)appRestored:(NSNotification*)note;
-(void)appEnteringBackground:(NSNotification*)note;
-(void)cacheImagesReferencedInHTML:(NSString*)html;
-(BOOL)loadImageIntoCache:(NSString*)imgPath;
-(void)loadKeyboard;
-(void)keyboardPrefsChanged:(NSNotification*)note;
@end

#pragma mark -

@implementation SessionViewController

-(id)initWithSession:(RCSession*)session
{
	self = [super initWithNibName:@"SessionViewController" bundle:nil];
	if (self) {
		_session = [session retain];
		_session.delegate = self;
		NSError *err=nil;
		self.autoReconnect=NO;
		NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
		NSURL *cacheUrl = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask
							appropriateForURL:nil create:YES error:&err];
		cacheUrl = [cacheUrl URLByAppendingPathComponent:@"Rimages"];
		if (![fm fileExistsAtPath:cacheUrl.path]) {
			BOOL result = [fm createDirectoryAtPath:[cacheUrl path]
						withIntermediateDirectories:YES
										 attributes:nil
											  error:&err];
			ZAssert(result, @"failed to create img cache directory: %@", [err localizedDescription]);
		}
		self.imgCachePath = [cacheUrl path];
		self.imgCache = [NSMutableDictionary dictionary];
		self.dloadQueue = [[[NSOperationQueue alloc] init] autorelease];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appRestored:) name: UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteringBackground:) name:  UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardPrefsChanged:) name:  KeyboardPrefsChangedNotification object:nil];
	}
	return self;
}

-(void)freeMemory
{
	self.themeToken=nil;
	self.jsQuiteRExp=nil;
	self.imgController=nil;
	self.imgCachePath=nil;
	self.imgCache=nil;
	self.dloadQueue=nil;
	self.editorController=nil;
	self.consoleController=nil;
}

- (void)dealloc
{
	[self freeMemory];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_session release];
    [super dealloc];
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
		[self.splitController layoutSubviewsForInterfaceOrientation:TheApp.statusBarOrientation withAnimation:NO];
	});
	
	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	self.splitController.dividerView.lightColor = [theme colorForKey:@"SessionPaneSplitterStart"];
	self.splitController.dividerView.darkColor = [theme colorForKey:@"SessionPaneSplitterEnd"];
	__block SessionViewController *blockSelf = self;
	id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *aTheme) {
		blockSelf.splitController.dividerView.lightColor = [aTheme colorForKey:@"SessionPaneSplitterStart"];
		blockSelf.splitController.dividerView.darkColor = [aTheme colorForKey:@"SessionPaneSplitterEnd"];
	}];
	self.themeToken = tn;
	[self.splitController.dividerView addShineLayer:self.splitController.dividerView.layer bounds:self.splitController.dividerView.bounds];
	
	RCSavedSession *savedState = self.session.savedSessionState;
	self.consoleController.session = self.session;
	[self.consoleController view]; //force loading
	[self.editorController view];
	[self.editorController restoreSessionState:savedState];
	[self.consoleController restoreSessionState:savedState];
	[self cacheImagesReferencedInHTML:savedState.consoleHtml];
	if (!self.session.socketOpen) {
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		hud.labelText = @"Connecting to server…";
		self.showingProgress = YES;
		[self.session startWebSocket];
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
	self.editorController.textView.inputView = self.keyboardView;
	self.keyboardView.textView = self.editorController.textView;
	self.keyboardView.delegate = self.editorController;
}

-(NSString*)escapeForJS:(NSString*)str
{
	if ([str isKindOfClass:[NSString class]])
		return [self.jsQuiteRExp stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@"\\'"];
	return [str description];
}


-(void)cacheImagesReferencedInHTML:(NSString*)html
{
	if (nil == html)
		return;
	NSError *err=nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"rc2img:///iR/images/([^\\.]+\\.png)" options:0 error:&err];
	ZAssert(nil == err, @"error compiling regex: %@", [err localizedDescription]);
	__block SessionViewController *blockSelf = self;
	[regex enumerateMatchesInString:html options:0 range:NSMakeRange(0, [html length]) 
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) 
						{
							NSString *fname = [html substringWithRange:[match rangeAtIndex:1]];
							[blockSelf loadImageIntoCache:fname];
						 }];
}


-(void)cacheImages:(NSArray*)urls
{
	for (NSString *str in urls) {
		NSString *fname = [str lastPathComponent];
		NSString *imgPath = [self.imgCachePath stringByAppendingPathComponent:fname];
		NSURL *url = [NSURL URLWithString:str];
		ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithURL:url];
		[req setDownloadDestinationPath: imgPath];
		__block SessionViewController *blockSelf = self;
		[req setCompletionBlock:^{
			RCImage *img = [[RCImage alloc] initWithPath:imgPath];
			img.name = [fname stringbyRemovingPercentEscapes];
			if ([img.name indexOf:@"#"] != NSNotFound)
				img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
			[blockSelf.imgCache setObject:img forKey:fname];
			[img release];
		}];
		[self.dloadQueue addOperation:req];
	}
}

-(NSArray*)adjustImageArray:(NSArray*)inArray
{
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	NSMutableArray *fetchArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	NSString *baseUrl = [[Rc2Server sharedInstance] baseUrl];
	for (NSString *aUrl in inArray) {
		[outArray addObject:[NSString stringWithFormat:@"rc2img://%@", aUrl]];
		[fetchArray addObject:[NSString stringWithFormat:@"%@%@", baseUrl, [aUrl substringFromIndex:1]]];
	}
	//now need to fetch images in background
	[self cacheImages:fetchArray];
	return outArray;
}

-(IBAction)endSession:(id)sender
{
	[_session setSetting:[NSNumber numberWithFloat:self.splitController.splitPosition] forKey:@"splitPosition"];
	self.autoReconnect=NO;
	[_session closeWebSocket];
	[self saveSessionState];
	[(id)[UIApplication sharedApplication].delegate endSession:sender];
}

#pragma mark - state management

-(void)saveSessionState
{
	RCSavedSession *savedState = _session.savedSessionState;
	savedState.consoleHtml = [self.consoleController.webView stringByEvaluatingJavaScriptFromString:@"$('#consoleOutputGenerated').html()"];
	savedState.currentFile = self.editorController.currentFile;
	if (nil == savedState.currentFile)
		savedState.inputText = self.editorController.textView.text;
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
	if (self.showingProgress)
		[MBProgressHUD hideHUDForView:self.view animated:YES];
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
	[self.consoleController.webView stringByEvaluatingJavaScriptFromString:cmd];
}

-(BOOL)loadImageIntoCache:(NSString*)imgPath
{
	imgPath = imgPath.lastPathComponent;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *fpath = [self.imgCachePath stringByAppendingPathComponent:imgPath];
	if (![fm fileExistsAtPath:fpath])
		return NO;
	RCImage *img = [[RCImage alloc] initWithPath:fpath];
	img.name = [imgPath stringbyRemovingPercentEscapes];
	if ([img.name indexOf:@"#"] != NSNotFound)
		img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
	[self.imgCache setObject:img forKey:imgPath];
	[img release];
	return YES;
}

-(void)displayImage:(NSString*)imgPath
{
	if (![self loadImageIntoCache:imgPath]) {
		//FIXME: display alert
		Rc2LogWarn(@"image does not exist: %@", imgPath);
		return;
	}
	self.imgController = [[[ImageDisplayController alloc] init] autorelease];
	self.imgController.allImages = [[self.imgCache allValues] sortedArrayUsingComparator:^(RCImage *obj1, RCImage *obj2) {
		if (obj1.timestamp > obj2.timestamp)
			return NSOrderedAscending;
		if (obj2.timestamp > obj1.timestamp)
			return NSOrderedDescending;
		return [obj1.name caseInsensitiveCompare:obj2.name];
	}];
	[self presentModalViewController:self.imgController animated:YES];
	[self.imgController loadImages];
	[self.imgController loadImage1:[self.imgCache objectForKey:[imgPath lastPathComponent]]];
}

-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
	NSString *cmd = [dict objectForKey:@"msg"];
	NSString *js=nil;
	Rc2LogInfo(@"processing ws command: %@", cmd);
	if ([cmd isEqualToString:@"userid"]) {
		js = [NSString stringWithFormat:@"iR.setUserid(%@)", [dict objectForKey:@"userid"]];
	} else if ([cmd isEqualToString:@"echo"]) {
		js = [NSString stringWithFormat:@"iR.echoInput('%@', '%@', %@)", 
			  	[self escapeForJS:[dict objectForKey:@"script"]],
			  [self escapeForJS:[dict objectForKey:@"username"]],
			  [self escapeForJS:[dict objectForKey:@"user"]]];
	} else if ([cmd isEqualToString:@"join"]) {
		js = [NSString stringWithFormat:@"iR.userJoinedSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"left"]) {
		js = [NSString stringWithFormat:@"iR.userLeftSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"userList"]) {
		js = [NSString stringWithFormat:@"iR.updateUserList(JSON.parse('%@'))", 
			  [[[dict objectForKey:@"data"] objectForKey:@"users"] JSONRepresentation]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"complexResults"]) {
			js = [NSString stringWithFormat:@"iR.appendComplexResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"json"]) {
			js = [NSString stringWithFormat:@"iR.appendResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		}
		if ([[dict objectForKey:@"imageUrls"] count] > 0) {
			NSArray *adjustedImages = [self adjustImageArray:[dict objectForKey:@"imageUrls"]];
			js = [NSString stringWithFormat:@"iR.appendImages(%@)",
				  [adjustedImages JSONRepresentation]];
		}
	} else if ([cmd isEqualToString:@"chat"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kChatMessageNotification object:nil 
														  userInfo:dict];
	}
	if (js) {
		[self.consoleController.webView stringByEvaluatingJavaScriptFromString:js];
		[self.consoleController.webView stringByEvaluatingJavaScriptFromString:@"scroll(0,document.body.scrollHeight)"];
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
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
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

- (float)splitViewController:(MGSplitViewController *)svc constrainSplitPosition:(float)proposedPosition splitViewSize:(CGSize)viewSize;
{
	CGFloat maxSize = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation) ? viewSize.width : viewSize.height;
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
	if (proposedPosition < 260)
		return 260;
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
@synthesize imgCachePath;
@synthesize imgCache;
@synthesize dloadQueue;
@synthesize imgController;
@synthesize reconnecting;
@synthesize autoReconnect;
@synthesize bottomController;
@synthesize themeToken;
@synthesize showingProgress;
@end
