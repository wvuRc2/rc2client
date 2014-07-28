//
//  Rc2AppDelegate.m
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Rc2AppDelegate.h"
#import "include/HockeySDK/HockeySDK.h"
#import "LoginController.h"
#import "SessionViewController.h"
#import "Rc2Server.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCSavedSession.h"
#import "RCFile.h"
#import "Rc2AppConstants.h"
#import "MLReachability.h"
#import <objc/runtime.h>
#import "MAKVONotificationCenter.h"
#import "FileImportViewController.h"
#import "ThemeEngine.h"
#import "ThemeColorViewController.h"
#import "SendMailController.h"
#import "ProjectViewController.h"
#import "ProjectViewTransition.h"
#import "iSettingsController.h"
#import "AMHudView.h"
#import "SSKeychain.h"

const CGFloat kIdleTimerFrequency = 5;
const CGFloat kMinIdleTimeBeforeAction = 20;

@interface Rc2AppDelegate() <BITHockeyManagerDelegate,BITUpdateManagerDelegate,UINavigationControllerDelegate> {
	NSManagedObjectModel *__mom;
}
@property (nonatomic, strong) MLReachability *reachability;
@property (nonatomic, strong) UINavigationController *rootNavController;
@property (nonatomic, strong) NSPersistentStoreCoordinator *myPsc;
@property (nonatomic, strong) LoginController *authController;
@property (nonatomic, strong) ThemeColorViewController *themeEditor;
@property (nonatomic, strong) UIView *messageListView;
@property (nonatomic, strong) UIView *currentMasterView;
@property (nonatomic, strong) NSData *pushToken;
@property (nonatomic, strong) NSURL *fileToImport;
@property (nonatomic, strong) AMHudView *currentHud;
@property (nonatomic, copy, readwrite) NSArray *standardLeftNavBarItems;
@property (nonatomic, copy, readwrite) NSArray *standardRightNavBarItems;
@property (nonatomic, strong) iSettingsController *isettingsController;
@property NSTimeInterval lastEventTime;
@property (nonatomic, strong) NSTimer *idleTimer;
@end

@implementation Rc2AppDelegate

#pragma mark - app delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[VyanaLogger sharedInstance] startLogging];
	[[VyanaLogger sharedInstance] setLogLevel:LOG_LEVEL_INFO forKey:@"rc2"];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"iOSDefaults" withExtension:@"plist"];
	NSDictionary *defs = [NSDictionary dictionaryWithContentsOfURL:url];
	ZAssert(defs, @"failed toload default defaults");
	url = [[NSBundle mainBundle] URLForResource:@"CommonDefaults" withExtension:@"plist"];
	NSMutableDictionary *allDefs = [NSMutableDictionary dictionaryWithContentsOfURL:url];
	ZAssert(allDefs, @"failed to load common defaults");
	[allDefs addEntriesFromDictionary:defs];
	[defaults registerDefaults:allDefs];
	 
#if !TARGET_IPHONE_SIMULATOR
	[[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"1ecec8cd34e796a9159794e9e86610ee" liveIdentifier:@"1ecec8cd34e796a9159794e9e86610ee" delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
	[BITHockeyManager sharedHockeyManager].debugLogEnabled = YES;
	[BITHockeyManager sharedHockeyManager].authenticator.authenticationSecret = @"3feb3562d8cc26b457d228d04aee497d";
#endif
	
	self.reachability = [MLReachability reachabilityForInternetConnection];
	self.reachability.reachableBlock = ^(MLReachability *reach){
		Rc2AppDelegate *del = (Rc2AppDelegate*)[UIApplication sharedApplication].delegate;
		[del networkReachable];
	};
	self.reachability.unreachableBlock = ^(MLReachability *reach){
		Rc2AppDelegate *del = (Rc2AppDelegate*)[UIApplication sharedApplication].delegate;
		[del networkUnreachable];
	};
	[self setupNavBarButtons];
	
	[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Rc2.sqlite"];
	[MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
	
	ProjectViewController *pvc = [[ProjectViewController alloc] init];
	UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:pvc];
	self.window.rootViewController = navc;
	navc.delegate = self;
	self.rootNavController = navc;
	self.window.tintColor = [UIColor colorWithHexString:@"003366"];
	[self.window makeKeyAndVisible];

	[(iAMApplication*)application sendDelegateEventNotifications];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self startLoginProcess];
	});

	DBSession *session = [[DBSession alloc] initWithAppKey:@"663yb1illxbs5rl" 
												  appSecret:@"on576o50uxrjxhj"
													  root:kDBRootDropbox];
	[DBSession setSharedSession:session];
	
	//disable nsurl caching since we'll do our own
	[NSURLCache setSharedURLCache:[[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil]];
	
	//make sure file cache folder exists
	NSString *cachePath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"files"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
	
	//setup audio
	AVAudioSession *asession = [AVAudioSession sharedInstance];
	NSError *aErr;
	if (![asession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&aErr])
		Rc2LogWarn(@"failed to set audio session category:%@", aErr);
	
	if (![asession setActive:YES error:&aErr])
		Rc2LogWarn(@"error activating audio session:%@", aErr);

	//in case were launched with a file to open
	self.fileToImport = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];

	//watch for login status
	Rc2Server *rc2 = [Rc2Server sharedInstance];
	if (rc2.loggedIn) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self completeFileImport];
		});
	} else {
		[self observeTarget:rc2 keyPath:@"loggedIn" options:0 block:^(MAKVONotification *note) {
#if !TARGET_IPHONE_SIMULATOR
			[BITHockeyManager sharedHockeyManager].authenticator.identificationType = BITAuthenticatorIdentificationTypeHockeyAppEmail;
			[[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif
			//#endif
			if (self.fileToImport)
				[self completeFileImport];
		}];
	}
	
	application.applicationIconBadgeNumber = 0;
	return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	if ([[DBSession sharedSession] handleOpenURL:url]) {
		if ([[DBSession sharedSession] isLinked]) {
			if (self.dropboxCompletionBlock)
				self.dropboxCompletionBlock();
		}
		return YES;
	} else if ([[url lastPathComponent] hasSuffix:@".pdf"] && [url.lastPathComponent hasPrefix:@"rc2g"]) {
//		[self.rootController handleGradingUrl:url];
		return YES;
	} else if ([url.scheme isEqualToString:@"file"] && url.isFileURL) {
		self.fileToImport = url;
		[self completeFileImport];
	}
	return NO;
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation;
{
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[self.idleTimer invalidate];
	self.idleTimer = nil;
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
	if (self.idleTimer)
		[self.idleTimer invalidate];
	self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:kIdleTimerFrequency repeats:YES usingBlock:^(NSTimer *timer) {
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		if ((now - self.lastEventTime) > kMinIdleTimeBeforeAction) {
			[[NSNotificationCenter defaultCenter] postNotificationName:RC2IdleTimerFiredNotification object:self];
			[self saveChangesIfNeeded];
			self.lastEventTime = now;
		}
	}];
	self.lastEventTime = [NSDate timeIntervalSinceReferenceDate];
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. 
	 If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[MagicalRecord cleanUp];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	NSLog(@"got note:%@", userInfo);
//	[self.rootController reloadNotifications];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"failed to reg: %@", error);
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	self.pushToken = deviceToken;
	[[Rc2Server sharedInstance] updateDeviceToken:deviceToken];
}

#pragma mark - actions

-(IBAction)logout:(id)sender
{
	[[Rc2Server sharedInstance] logout];
//	[self.rootController showWelcome];
	CGFloat delay = 0.1;
	if (self.window.rootViewController.presentedViewController != nil)
		delay = 0.5;
	RunAfterDelay(delay, ^{
		[self promptForLogin];
	});
}

-(IBAction)editTheme:(id)sender
{
	if (self.themeEditor) {
		//already visible. get rid of it
		[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
		self.themeEditor=nil;
		return;
	}
	self.themeEditor = [[ThemeColorViewController alloc] init];
	self.themeEditor.modalPresentationStyle = UIModalPresentationPageSheet;
	__weak Rc2AppDelegate *bself = self;
	self.themeEditor.completionBlock = ^{
		bself.themeEditor=nil;
		RunAfterDelay(0.5, ^{ [bself sendThemeMail]; });
	};
	[self.window.rootViewController presentViewController:self.themeEditor animated:YES completion:nil];
	self.themeEditor.view.superview.frame = CGRectMake(112, 80, 800, 600);
}

-(void)sendThemeMail
{
	__block SendMailController *smc = [[SendMailController alloc] init];
	NSData *data = [[[ThemeEngine sharedInstance] customTheme] plistContents];
	[smc.composer setSubject:@"Custom Theme Save"];
	[smc.composer setToRecipients:@[@"rc2@stat.wvu.edu"]];
	[smc.composer addAttachmentData:data mimeType:@"text/xml" fileName:@"customTheme.plist"];
	[self.window.rootViewController presentViewController:smc.composer animated:YES completion:nil];
}

-(void)showGearMenu:(id)sender
{
	if (self.isettingsPopover) {
		//alraady displauing it, so dimiss it
		[self.isettingsPopover dismissPopoverAnimated:YES];
		self.isettingsPopover=nil;
		return;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kWillDisplayGearMenu object:self.isettingsPopover];
	if (nil == self.isettingsController) {
		self.isettingsController = [[iSettingsController alloc] init];
		self.isettingsController.preferredContentSize = CGSizeMake(350, 430);
	}
	id frontController = self.rootNavController.topViewController;
	if ([frontController respondsToSelector:@selector(workspaceForSettings)])
		self.isettingsController.currentWorkspace = [frontController workspaceForSettings];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.isettingsController];
	self.isettingsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
	[self.isettingsPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	self.isettingsController.containingPopover = self.isettingsPopover;
}

#pragma mark - reachability

-(void)networkReachable
{
	NSLog(@"network became reachable:%@", self.reachability.currentReachabilityString);
}

-(void)networkUnreachable
{
	NSLog(@"network became unreachable:%@", self.reachability.currentReachabilityString);	
}

#pragma mark - private

-(void)setupNavBarButtons
{
	self.standardLeftNavBarItems = @[];
	
	NSMutableArray *rightItems = [NSMutableArray arrayWithCapacity:3];
	UIBarButtonItem *gearItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] style:UIBarButtonItemStyleBordered target:self action:@selector(showGearMenu:)];
	[rightItems addObject:gearItem];
	//	UIBarButtonItem *homeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home-tbar"] style:UIBarButtonItemStyleBordered target:self action:@selector(showProjects:)];
	//	[rightItems addObject:homeItem];
	//	UIBarButtonItem *mailItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"messages-tbar"] style:UIBarButtonItemStyleBordered target:self action:@selector(showMessages:)];
	//	[rightItems addObject:mailItem];
	self.standardRightNavBarItems = rightItems;
}

#pragma mark - navigation controller delegate

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (self.sessionController && [viewController isKindOfClass:[AbstractProjectViewController class]]) {
		[self endSession:nil];
	}
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	self.isettingsController = nil;
}

-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
//	if ([fromVC isKindOfClass:[AbstractProjectViewController class]] && [toVC isKindOfClass:[AbstractProjectViewController class]])
		return [[ProjectViewTransition alloc] initWithFromController:(AbstractProjectViewController*)fromVC toController:(AbstractProjectViewController*)toVC];
//	return nil;
}

#pragma mark - meat & potatoes

-(void)completeFileImport
{
	if (self.fileToImport) {
		__block FileImportViewController *ic = [[FileImportViewController alloc] init];
		ic.inputUrl = self.fileToImport;
		__block UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ic];
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		ic.cleanupBlock = ^{
			nc=nil;
		};
		[self.window.rootViewController presentViewController:nc animated:YES completion:^{}];
		NSFileManager *fm = [[NSFileManager alloc] init];
		[fm removeItemAtURL:self.fileToImport error:nil];

		//the following can likely be deleted. It was here because originally we weren't deleting imported files, therefore causing the name
		// to be mangled in-order to be unique
		NSArray *existFiles = [fm contentsOfDirectoryAtURL:[self.fileToImport URLByDeletingLastPathComponent] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
		for (NSURL *aFile in existFiles) {
			[fm removeItemAtURL:aFile error:nil];
		}
	}
	self.fileToImport = nil;
}

-(void)completeSessionStartup:(id)results selectedFile:(RCFile*)selFile workspace:(RCWorkspace*)wspace
{
	if ([[results objectForKey:@"status"] intValue] != 0) {
		Rc2LogWarn(@"error on session startup:%@", [results objectForKey:@"message"]);
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
														message:[results objectForKey:@"message"]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[self.currentHud hide];
		self.currentHud=nil;
		return;
	}
	RCSession *session = [[RCSession alloc] initWithWorkspace:wspace serverResponse:results];
	session.initialFileSelection = selFile;
	SessionViewController *svc = [[SessionViewController alloc] initWithSession:session];
	self.sessionController = svc;
	[svc view];
	[self.currentHud hide];
	self.currentHud=nil;
//	RunAfterDelay(0.25, ^{
		[self.rootNavController pushViewController:svc animated:YES];
//	});
}

-(void)openSession:(RCWorkspace*)wspace
{
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:wspace];
	BOOL restoring = nil != savedState;
	self.currentHud = [AMHudView hudWithLabelText:restoring ? @"Restoring session…" : @"Loading…"];
	[self.currentHud showOverView:self.rootNavController.view];
	[[Rc2Server sharedInstance] prepareWorkspace:wspace completionHandler:^(BOOL success, id response) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self completeSessionStartup:response selectedFile:nil workspace:wspace];
			});
		} else {
			[self.currentHud hide];
			self.currentHud = nil;
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
															message:response
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}];
}

-(void)startSession:(RCFile*)initialFile workspace:(RCWorkspace*)wspace
{
	if ([initialFile.name.pathExtension isEqualToString:@"pdf"]) {
		[self displayPdfFile:initialFile];
		return;
	}
	ZAssert(wspace, @"startSession called without a selected workspace");
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:wspace];
	BOOL restoring = nil != savedState;
	self.currentHud = [AMHudView hudWithLabelText:restoring ? @"Restoring session…" : @"Loading…"];
	[self.currentHud showOverView:self.rootNavController.view];
	[[Rc2Server sharedInstance] prepareWorkspace: wspace completionHandler:^(BOOL success, id response) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self completeSessionStartup:response selectedFile:initialFile workspace:wspace];
			});
		} else {
			[self.currentHud hide];
			self.currentHud=nil;
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
	[self.sessionController endSession];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPref_CurrentSessionWorkspace];
	self.sessionController=nil;
}

-(void)restoreLastSession
{
	NSNumber *wspaceId = [[NSUserDefaults standardUserDefaults] objectForKey:kPref_CurrentSessionWorkspace];
	if (wspaceId) {
		RCWorkspace *wspace = [[Rc2Server sharedInstance] workspaceWithId:wspaceId];
		if (wspace)
			[self startSession:nil workspace:wspace];
	}
}

-(void)registerForPushNotification
{
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge];
}

-(void)startLoginProcess
{
	Rc2Server *rc2 = [Rc2Server sharedInstance];
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastLogin];
	if (nil == login) {
		[self promptForLogin];
		return;
	}
	NSString *pass = [SSKeychain passwordForService:@"Rc2" account:login];
	if (nil == pass) {
		[self promptForLogin];
		return;
	}
	[rc2 loginAsUser:login password:pass completionHandler:^(BOOL success, id results) {
		if (success) {
#ifndef TARGET_IPHONE_SIMULATOR
			[self registerForPushNotification];
#endif
			if ([[NSUserDefaults standardUserDefaults] objectForKey:kPref_CurrentSessionWorkspace])
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
	__weak Rc2AppDelegate *blockSelf = self;
	self.authController.loginCompleteHandler = ^ {
		[blockVC dismissViewControllerAnimated:YES completion:nil];
		blockSelf.authController=nil;
#if !TARGET_IPHONE_SIMULATOR
		[blockSelf registerForPushNotification];
#endif
		if ([[NSUserDefaults standardUserDefaults] objectForKey:kPref_CurrentSessionWorkspace]) {
			[blockSelf restoreLastSession];
		}
	};
	self.authController.transitioningDelegate = self.authController;
	self.authController.modalPresentationStyle = UIModalPresentationCustom;
	[UIViewController attemptRotationToDeviceOrientation];
	[blockVC presentViewController:self.authController animated:YES completion:nil];
}


-(void)saveChangesIfNeeded
{
	NSManagedObjectContext *moc = [NSManagedObjectContext MR_defaultContext];
	if (moc.hasChanges) {
		[moc MR_saveToPersistentStoreAndWait];
	}
}

//this is called even when swithing to background or will terminate is about to happen.
-(void)eventLoopComplete:(UIEvent*)event
{
	[self saveChangesIfNeeded];
	self.lastEventTime = [NSDate timeIntervalSinceReferenceDate];
}

#pragma mark - pdf display

-(void)displayPdfFile:(RCFile*)file
{
	ZAssert([file.name hasSuffix:@".pdf"], @"non-pdf file pased to displayPdf:");
	if (![[NSFileManager defaultManager] fileExistsAtPath:file.fileContentsPath]) {
		Rc2LogWarn(@"displayPdfFile: called without content downloaded");
		[[Rc2Server sharedInstance] fetchBinaryFileContentsSynchronously:file];
	}
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


@end

