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
#import "DetailsViewController.h"
#import "Rc2Server.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCSavedSession.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "DropboxSDK.h"
#import "AppConstants.h"

//hack for iOS 5.0 SDK bug
@implementation UIImage(iOS5HackBugFix)
-(id)initWithCoder:(NSCoder *)aDecoder
{
	return nil;
}
@end

@interface Rc2AppDelegate() {
	NSPersistentStoreCoordinator *__psc;
	NSManagedObjectModel *__mom;
	NSInteger _curKeyFile;
}
@property (nonatomic, retain) LoginController *authController;
@property (nonatomic, retain) UIView *messageListView;
@property (nonatomic, retain) UIView *currentMasterView;
@property (nonatomic, retain) DBRestClient *keyboardRestClient;
-(void)downloadKeyboardFile;
@end

#define kCustomKeyboardDBPathTemplate @"/rc2shares/keyboards/custom%d-%d%@.txt"

@implementation Rc2AppDelegate

@synthesize window=_window;
@synthesize authController=_authController;
@synthesize splitController=_splitController;
@synthesize navController=_navController;
@synthesize detailsController=_detailsController;
@synthesize sessionController=_sessionController;
@synthesize currentMasterView;
@synthesize messageListView;
@synthesize keyboardRestClient;

#pragma mark - app delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	 
	[self.window makeKeyAndVisible];
	[[Rc2Server sharedInstance] addObserverForKeyPath:@"loggedIn" task:^(id obj, NSDictionary *change) {
		[(WorkspaceTableController*)self.navController.topViewController 
		 setWorkspaceItems:[[Rc2Server sharedInstance] workspaceItems]];
	}];
	[(iAMApplication*)application sendDelegateEventNotifications];
	[self promptForLogin];

	DBSession *session = [[[DBSession alloc] initWithConsumerKey:@"663yb1illxbs5rl" 
												  consumerSecret:@"on576o50uxrjxhj"] autorelease];
	[DBSession setSharedSession:session];
	[TestFlight takeOff:@"77af1fa93381361c61748e58fae9f4f9_Mjc0ODAyMDExLTA5LTE5IDE2OjUwOjU3LjYzOTg1Mw"];
	return YES;
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

#pragma mark - meat & potatoes

-(void)resetKeyboardPaths
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSBundle *mb = [NSBundle mainBundle];
	[defaults setObject:[mb pathForResource:@"rightAlpha" ofType:@"txt"] forKey:kPrefCustomKey1URL];
	[defaults setObject:[mb pathForResource:@"rightSym" ofType:@"txt"] forKey:kPrefCustomKey2URL];		
}

-(IBAction)flipMasterView:(UIView*)otherView
{
	if (self.currentMasterView == self.navController.view) {
			[UIView transitionFromView:self.navController.view
								toView:otherView
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromLeft
							completion:^(BOOL finished) { }];
		self.currentMasterView = self.messageListView;
	} else {
			[UIView transitionFromView:otherView
								toView:self.navController.view
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromRight
							completion:^(BOOL finished) {}];
		self.currentMasterView = self.navController.view;
	}
}

-(void)completeSessionStartup2
{
	SessionViewController *svc = [[SessionViewController alloc] initWithSession:[Rc2Server sharedInstance].currentSession];
	self.sessionController = svc;
	[svc release];
	[svc view];
	[MBProgressHUD hideHUDForView:self.splitController.view animated:YES];
	NSLog(@"should be opening session");
	RunAfterDelay(0.25, ^{
		[self.splitController presentModalViewController:svc animated:YES];
	});
}

-(void)completeSessionStartup:(id)results
{
	RCWorkspace *wspace = [Rc2Server sharedInstance].selectedWorkspace;
	RCSession *session = [[RCSession alloc] initWithWorkspace:wspace serverResponse:results];
	[Rc2Server sharedInstance].currentSession = session;
	[session release];
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

-(void)startSession
{
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
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.splitController.view animated:YES];
	hud.labelText = restoring ? @"Restoring session…" : @"Loading…";
	[[Rc2Server sharedInstance] prepareWorkspace:^(BOOL success, id response) {
		if (success) {
			[self performSelector:@selector(completeSessionStartup:) withObject:response afterDelay:0.1];
		} else {
			[MBProgressHUD hideHUDForView:self.splitController.view animated:YES];
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
	[self.splitController dismissModalViewControllerAnimated:YES];
	[self.detailsController refreshDetails];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"currentSessionWspaceId"];
}

-(void)restoreLastSession
{
	NSNumber *wspaceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentSessionWspaceId"];
	if (wspaceId) {
		[[Rc2Server sharedInstance] selecteWorkspaceWithId:wspaceId];
		if ([Rc2Server sharedInstance].selectedWorkspace)
			[self startSession];
	}
}

-(void)promptForLogin
{
	self.authController = [[[LoginController alloc] init] autorelease];
	__block UIViewController *blockVC = self.window.rootViewController;
	self.authController.loginCompleteHandler = ^ {
		[blockVC dismissModalViewControllerAnimated:YES];
		Rc2AppDelegate *del = ((Rc2AppDelegate*)[[UIApplication sharedApplication] delegate]);
		del.authController=nil;
		[(WorkspaceTableController*)self.navController.topViewController 
							setWorkspaceItems:[[Rc2Server sharedInstance] workspaceItems]];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"currentSessionWspaceId"]) {
			[del restoreLastSession];
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
	CGPoint centerPt = CGPointZero;
	centerPt.x = 512;
	centerPt.y = 100 + floor(sz.height/2);
	self.authController.view.superview.center = centerPt;
}

- (void)dealloc
{
	[_window release];
	[super dealloc];
}

//this is called even when swithing to background or will terminate is about to happen.
-(void)eventLoopComplete:(UIEvent*)event
{
	NSManagedObjectContext *moc = self.managedObjectContext;
	if (moc.hasChanges) {
		//save any changes
		NSError *err=nil;
		if (![moc save:&err]) {
			NSLog(@"failed to save moc changes: %@", err);
		}
	}
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
	NSLog(@"saved file %@", destPath);
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
		NSLog(@"successfully downloaded custom keyboard layouts");
	}
	[self completeSessionStartup2];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
	NSLog(@"keyboard import error: %@", [error localizedDescription]);
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
	moc = [[[NSManagedObjectContext alloc] init] autorelease];
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
	@synchronized(self) {
		if (__psc)
			return __psc;
		
		NSURL *storeURL = [[self applicationDocumentsDirectory] 
						   URLByAppendingPathComponent:@"Rc2.sqlite"];
		
		NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
															forKey:NSMigratePersistentStoresAutomaticallyOption];
		NSError *error = nil;
	LOADFILE:
		__psc = [[NSPersistentStoreCoordinator alloc] 
										initWithManagedObjectModel:[self managedObjectModel]];
		if (![__psc addPersistentStoreWithType:NSSQLiteStoreType 
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
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}    
	}
	return __psc;
}


@end
