//
//  Rc2AppDelegate.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "Rc2AppDelegate.h"
#import "LoginController.h"
#import "WorkspaceTableController.h"
#import "SessionViewController.h"
#import "RootViewController.h"
#import "Rc2Server.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCSavedSession.h"
#import "RCFile.h"
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"
#import "AppConstants.h"
#import <objc/runtime.h>

@interface UITableView (DoubleClick)
-(void)myTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@interface Rc2AppDelegate() {
	NSManagedObjectModel *__mom;
	NSInteger _curKeyFile;
}
@property (nonatomic, strong) RootViewController *rootController;
@property (nonatomic, strong) NSPersistentStoreCoordinator *myPsc;
@property (nonatomic, strong) LoginController *authController;
@property (nonatomic, strong) UIView *messageListView;
@property (nonatomic, strong) UIView *currentMasterView;
@property (nonatomic, strong) DBRestClient *keyboardRestClient;
@property (nonatomic, strong) NSData *pushToken;
-(void)downloadKeyboardFile;
@end

#define kCustomKeyboardDBPathTemplate @"/rc2shares/keyboards/custom%d-%d%@.txt"
static void MyAudioInterruptionCallback(void *inUserData, UInt32 interruptionState);

@implementation Rc2AppDelegate

@synthesize window=_window;
@synthesize authController=_authController;
@synthesize sessionController=_sessionController;
@synthesize currentMasterView;
@synthesize messageListView;
@synthesize keyboardRestClient;
@synthesize pushToken;

#pragma mark - app delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[VyanaLogger sharedInstance] startLogging];
	[[VyanaLogger sharedInstance] setLogLevel:LOG_LEVEL_INFO forKey:@"rc2"];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[(iAMApplication*)application loadDefaultDefaults];
	 
	//swizzle UITableView method so can get double click notifications
	Method customMethod = class_getInstanceMethod([UITableView class], @selector(myTouchesEnded:withEvent:));
	Method origMethod = class_getInstanceMethod([UITableView class], @selector(touchesEnded:withEvent:));
	method_exchangeImplementations(origMethod, customMethod);

#ifndef CONFIGURATION_Debug
	[[BWHockeyManager sharedHockeyManager] setAppIdentifier:@"1ecec8cd34e796a9159794e9e86610ee"];
	[[BWHockeyManager sharedHockeyManager] setDelegate:self];
#endif
	
	self.rootController = [[RootViewController alloc] init];
	self.window.rootViewController = self.rootController;
	[self.window addSubview:self.rootController.view];
	[self.window makeKeyAndVisible];

	[(iAMApplication*)application sendDelegateEventNotifications];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self startLoginProcess];
	});

	DBSession *session = [[DBSession alloc] initWithAppKey:@"663yb1illxbs5rl" 
												  appSecret:@"on576o50uxrjxhj"
													  root:kDBRootDropbox];
	[DBSession setSharedSession:session];
	
	//make sure file cache folder exists
	NSString *cachePath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"files"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
	
	//setup audio
	AudioSessionInitialize(NULL, NULL, MyAudioInterruptionCallback, (__bridge void*)self);
	SInt32 category = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	AudioSessionSetActive(true);
	
	//FIXME: temporary
	application.applicationIconBadgeNumber = 0;
	return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
			NSLog(@"dropbox linked");
			if (self.dropboxCompletionBlock)
				self.dropboxCompletionBlock();
		}
		return YES;
	} else if ([[url lastPathComponent] hasSuffix:@".pdf"] && [url.lastPathComponent hasPrefix:@"rc2g"]) {
		[self.rootController handleGradingUrl:url];
		return YES;
	}
	return NO;
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation;
{
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. 
	 If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	NSLog(@"got note:%@", userInfo);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"failed to reg: %@", error);
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	self.pushToken = deviceToken;
	ASIFormDataRequest *theReq = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"user"];
	[theReq setRequestMethod:@"PUT"];
	NSDictionary *d = [NSDictionary dictionaryWithObject:[deviceToken hexidecimalString] forKey:@"token"];
	[theReq appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[theReq addRequestHeader:@"Content-Type" value:@"application/json"];
	[theReq startAsynchronous];
}

#pragma mark - actions

-(IBAction)showWelcome:(id)sender
{
	[self.rootController showWelcome];
}

-(IBAction)showMessages:(id)sender
{
	[self.rootController showMessages];
}

-(IBAction)showWorkspaces:(id)sender
{
	[self.rootController showWorkspaces];
}

-(IBAction)showGrading:(id)sender
{
	[self.rootController showGrading];
}

-(IBAction)logout:(id)sender
{
	[[Rc2Server sharedInstance] logout];
	[self.rootController showWelcome];
	[self promptForLogin];
}

#pragma mark - meat & potatoes

-(void)resetKeyboardPaths
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSBundle *mb = [NSBundle mainBundle];
	[defaults setObject:[mb pathForResource:@"rightAlpha" ofType:@"txt"] forKey:kPrefCustomKey1URL];
	[defaults setObject:[mb pathForResource:@"rightSym" ofType:@"txt"] forKey:kPrefCustomKey2URL];		
}

-(void)completeSessionStartup2
{
	SessionViewController *svc = [[SessionViewController alloc] initWithSession:[Rc2Server sharedInstance].currentSession];
	self.sessionController = svc;
	[svc view];
	[MBProgressHUD hideHUDForView:self.rootController.view animated:YES];
	RunAfterDelay(0.25, ^{
		[self.rootController presentModalViewController:svc animated:YES];
	});
}

-(void)completeSessionStartup:(id)results selectedFile:(RCFile*)selFile
{
	RCWorkspace *wspace = [Rc2Server sharedInstance].selectedWorkspace;
	RCSession *session = [[RCSession alloc] initWithWorkspace:wspace serverResponse:results];
	[Rc2Server sharedInstance].currentSession = session;
	session.initialFileSelection = selFile;
	eKeyboardLayout keylayout = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefKeyboardLayout];
	if (keylayout != eKeyboardLayout_Standard) {
		_curKeyFile=0;
		//we need to attempt to copy custom keyboards from dropbox
		if (nil == self.keyboardRestClient) {
			self.keyboardRestClient = [[DBRestClient alloc] initWithSession:(id)[DBSession sharedSession]];
			self.keyboardRestClient.delegate = (id)self;
		}
		[self downloadKeyboardFile];
	} else {
		[self completeSessionStartup2];
	}
}

-(void)startSession:(RCFile*)initialFile
{
	if ([initialFile.name.pathExtension isEqualToString:@"pdf"]) {
		[self displayPdfFile:initialFile];
		return;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	eKeyboardLayout keylayout = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefKeyboardLayout];
	if (eKeyboardLayout_Standard == keylayout) {
		[self resetKeyboardPaths];
	} else {
		NSString *basePath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"customKeyboard"];
		[defaults setObject:[basePath stringByAppendingString:@"1.txt"] forKey:kPrefCustomKey1URL];
		[defaults setObject:[basePath stringByAppendingString:@"2.txt"] forKey:kPrefCustomKey2URL];
	}
	RCWorkspace *wspace = [Rc2Server sharedInstance].selectedWorkspace;
	ZAssert(wspace, @"startSession called without a selected workspace");
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:wspace];
	BOOL restoring = nil != savedState;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.rootController.view animated:YES];
	hud.labelText = restoring ? @"Restoring session…" : @"Loading…";
	[[Rc2Server sharedInstance] prepareWorkspace:^(BOOL success, id response) {
		if (success) {
			double delayInSeconds = 0.1;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[self completeSessionStartup:response selectedFile:initialFile];
			});
		} else {
			[MBProgressHUD hideHUDForView:self.rootController.view animated:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
															message:response
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}];
}

-(IBAction)endSession:(id)sender
{
	[self.rootController dismissModalViewControllerAnimated:YES];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentSessionWspaceId"];
	self.sessionController=nil;
}

-(void)restoreLastSession
{
	NSNumber *wspaceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentSessionWspaceId"];
	if (wspaceId) {
		[[Rc2Server sharedInstance] selectWorkspaceWithId:wspaceId];
		if ([Rc2Server sharedInstance].selectedWorkspace)
			[self startSession:nil];
	}
}

-(void)registerForPushNotification
{
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge];
}

-(void)startLoginProcess
{
	//FIXME: show progress dialog
	Rc2Server *rc2 = [Rc2Server sharedInstance];
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastLogin];
	if (nil == login) {
		[self promptForLogin];
		return;
	}
	NSString *pass = [SFHFKeychainUtils getPasswordForUsername:login andServiceName:@"Rc2" error:nil];
	if (nil == pass) {
		[self promptForLogin];
		return;
	}
	[rc2 loginAsUser:login password:pass completionHandler:^(BOOL success, id results) {
		if (success) {
			[self registerForPushNotification];
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"currentSessionWspaceId"])
				[self performSelectorOnMainThread:@selector(restoreLastSession) withObject:nil waitUntilDone:NO];
		} else {
			[self performSelectorOnMainThread:@selector(promptForLogin) withObject:nil waitUntilDone:NO];
		}
	}];
}

-(void)promptForLogin
{
	self.authController = [[LoginController alloc] init];
	__weak UIViewController *blockVC = self.window.rootViewController;
	__unsafe_unretained Rc2AppDelegate *blockSelf = self;
	self.authController.loginCompleteHandler = ^ {
		[blockVC dismissModalViewControllerAnimated:YES];
		blockSelf.authController=nil;
		[blockSelf registerForPushNotification];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"currentSessionWspaceId"]) {
			[blockSelf restoreLastSession];
		}
	};
	self.authController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self.authController view];
	CGSize sz = self.authController.view.frame.size;
	[blockVC presentModalViewController:self.authController animated:YES];


   self.authController.view.superview.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
	| UIViewAutoresizingFlexibleBottomMargin;
	CGRect r = self.authController.view.superview.frame;
	r.size = sz;
	self.authController.view.superview.frame = r;

	BOOL land = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
	CGSize screenSize = land ? CGSizeMake(1024, 748) : CGSizeMake(768, 1004);
	CGPoint pt = CGPointMake(screenSize.width/2, floor(screenSize.height/3));
	self.authController.view.superview.center = pt;
}


-(NSString *)customDeviceIdentifier 
{
	if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
		return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
	return nil;
}

//this is called even when swithing to background or will terminate is about to happen.
-(void)eventLoopComplete:(UIEvent*)event
{
	NSManagedObjectContext *moc = self.managedObjectContext;
	if (moc.hasChanges) {
		//save any changes
		NSError *err=nil;
		if (![moc save:&err]) {
			Rc2LogError(@"failed to save moc changes: %@", err);
		}
	}
}

#pragma mark - pdf display

-(void)displayPdfFile:(RCFile*)file
{
	ZAssert([file.name hasSuffix:@".pdf"], @"non-pdf file pased to displayPdf:");
	UIDocumentInteractionController *dic = [UIDocumentInteractionController interactionControllerWithURL:
											[NSURL fileURLWithPath:[file fileContentsPath]]];
	dic.delegate = (id)self;
	[dic presentPreviewAnimated:YES];	
}

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller
{
	if (self.sessionController)
		return self.sessionController;
	return self.window.rootViewController;
}


#pragma mark - drop box

-(void)downloadKeyboardFile
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	eKeyboardLayout keylayout = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefKeyboardLayout];
	NSInteger keyid = (_curKeyFile == 0 || _curKeyFile == 2) ? 1 : 2;
	NSString *keyad = (_curKeyFile > 1) ? @"p" : @"";
	NSString *path = [NSString stringWithFormat:kCustomKeyboardDBPathTemplate, keylayout, keyid, keyad];
	_curKeyFile++;
	//we need to attempt to copy custom keyboards from dropbox
	NSString *baseDest = [defaults objectForKey:keyid == 1 ? kPrefCustomKey1URL : kPrefCustomKey2URL];
	NSString *dest = [[baseDest stringByDeletingPathExtension] stringByAppendingFormat:@"%@.txt", keyad];
	[self.keyboardRestClient loadFile:path intoPath:dest];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
	Rc2LogInfo(@"saved file %@", destPath);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (_curKeyFile < 4) {
		[self downloadKeyboardFile];
		return;
	}
	NSString *path1 = [defaults objectForKey:kPrefCustomKey1URL];
	NSString *path2 = [defaults objectForKey:kPrefCustomKey2URL];
	//we should have 2 files saved on the filesystem. if not, reset to default keyboard
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:path1] || ![fm fileExistsAtPath:path2]) {
		[self resetKeyboardPaths];
	} else {
		Rc2LogInfo(@"successfully downloaded custom keyboard layouts");
	}
	[self completeSessionStartup2];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
	Rc2LogInfo(@"keyboard import error: %@", [error localizedDescription]);
	[self resetKeyboardPaths];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self completeSessionStartup2];
	});
}


#pragma mark - core data

//Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
	NSString *path =  [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
														   NSUserDomainMask, YES) objectAtIndex:0];
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:path])
		[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:0 error:nil];
	return [NSURL fileURLWithPath:path];
}


-(NSManagedObjectContext *)managedObjectContext
{
	NSManagedObjectContext *moc = [[[NSThread currentThread] threadDictionary] objectForKey:@"appMoc"];
	if (moc)
		return moc;
	//now we need to create a moc. this will require differences based on what thread we are on
	moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator: self.persistentStoreCoordinator];
	[[[NSThread	currentThread] threadDictionary] setObject:moc forKey:@"appMoc"];
	return moc;
}

-(NSManagedObjectModel *)managedObjectModel
{
	if (__mom)
		return __mom;
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Rc2" withExtension:@"momd"];
	__mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	return __mom;
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	NSPersistentStoreCoordinator *psc = self.myPsc;
	@synchronized(self) {
		if (psc)
			return psc;
		
		NSURL *storeURL = [[self applicationDocumentsDirectory] 
						   URLByAppendingPathComponent:@"Rc2.sqlite"];
		
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
															forKey:NSMigratePersistentStoresAutomaticallyOption];
		NSError *error = nil;
	LOADFILE:
		psc = [[NSPersistentStoreCoordinator alloc] 
										initWithManagedObjectModel:[self managedObjectModel]];
		if (![psc addPersistentStoreWithType:NSSQLiteStoreType 
														configuration:nil URL:storeURL options:options error:&error])
		{
			if (([error code] >= NSPersistentStoreIncompatibleVersionHashError) &&
				([error code] <= NSEntityMigrationPolicyError))
			{
				//migration failed. we'll just nuke the store and try again
				[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
				goto LOADFILE;
			}

			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 
			 Typical reasons for an error here include:
			 * The persistent store is not accessible;
			 Check the error message to determine what the actual problem was.
			 
			 
			 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
			 */
			Rc2LogError(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
		self.myPsc = psc;
	}
	return psc;
}

@synthesize myPsc;
@synthesize dropboxCompletionBlock;
@synthesize rootController=_rootController;
@end

@implementation UITableView (DoubleClick)
-(void)myTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *aTouch in touches) {
		if (aTouch.tapCount == 2)
			[[NSNotificationCenter defaultCenter] postNotificationName:kTableViewDoubleClickedNotification 
																object:self];
	}
	[self myTouchesEnded:touches withEvent:event]; //calls original 'cause we've been swizzled
}
@end


static void MyAudioInterruptionCallback(void *inUserData, UInt32 interruptionState)
{
	
}
