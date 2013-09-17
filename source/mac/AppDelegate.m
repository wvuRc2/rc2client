//
//  AppDelegate.m
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "AppDelegate.h"
#import "RCMAppConstants.h"
#import "MCLoginController.h"
#import "MCMainWindowController.h"
#import "Rc2Server.h"
#import "MCSessionViewController.h"
#import "RCMPDFViewController.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCMacToolbarItem.h"
#import "ThemeEngine.h"
#import "BBEdit.h"
#import "RCMGeneralPrefs.h"
#import "RCMFontPrefs.h"
//#import <HockeySDK/HockeySDK.h>
#import "MASPreferencesWindowController.h"
#import <DropboxOSX/DropboxOSX.h>

#define kPref_LastLoginString @"LastLoginString"
#define kPref_StartInFullScreen @"StartInFullScreen"

@interface AppDelegate() /*<BITCrashReportManagerDelegate> */ {
	BOOL __haveMoc;
	BOOL __firstLogin;
}
@property (strong) MCLoginController *loginController;
@property (readwrite, strong, nonatomic) MCMainWindowController *mainWindowController;
@property (nonatomic, strong) MASPreferencesWindowController *prefsController;
@property (nonatomic, strong) NSTimer *autosaveTimer;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite) BOOL isFullScreen;
@property (nonatomic, retain) BBEditApplication *bbedit;
-(void)handleSucessfulLogin;
-(NSManagedObjectContext*)managedObjectContext:(BOOL)create;
-(void)autoSaveChanges;
-(void)presentLoginPanel;
-(void)windowWillClose:(NSNotification*)note;
@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;

-(void)showMainApplicationWindow
{
	[self presentLoginPanel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	__firstLogin=YES;
	[[VyanaLogger sharedInstance] startLogging];
	[[VyanaLogger sharedInstance] setLogLevel:LOG_LEVEL_INFO forKey:@"rc2"];

#if DEBUG
	//if F-Script is available, install in menu bar
	Class fscriptClz = NSClassFromString(@"FScriptMenuItem");
	if (fscriptClz)
		[[NSApp mainMenu] addItem:[[fscriptClz alloc] init]];
	[self showMainApplicationWindow];
#else
	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"f4225a0ff7ed8fe53eb30f4a29a21689" companyName:@"WVU Statistics Dept" crashReportManagerDelegate:self];
	[[BITHockeyManager sharedHockeyManager] setExceptionInterceptionEnabled:!YES];
	[[BITHockeyManager sharedHockeyManager] startManager];
#endif

	DBSession *session = [[DBSession alloc] initWithAppKey:@"663yb1illxbs5rl"
												 appSecret:@"on576o50uxrjxhj"
													  root:kDBRootDropbox];
	[DBSession setSharedSession:session];
	NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];// 1
	[appleEventManager setEventHandler:self
						   andSelector:@selector(handleGetURLEvent:withReplyEvent:)
						 forEventClass:kInternetEventClass
							andEventID:kAEGetURL];

	
	NSString *fileCache = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"files"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileCache])
		[[NSFileManager defaultManager] createDirectoryAtPath:fileCache withIntermediateDirectories:YES attributes:nil error:nil];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[self storeNotificationToken:[nc addObserverForName:NSWindowDidEnterFullScreenNotification object:nil queue:nil 
											 usingBlock:^(NSNotification *note)
	{
	  	self.isFullScreen = YES;
	}]];
	[self storeNotificationToken:[nc addObserverForName:NSWindowDidExitFullScreenNotification object:nil queue:nil 
											 usingBlock:^(NSNotification *note)
	{
		self.isFullScreen = NO;
	}]];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
	[self setupThemeMenu];
}

-(BOOL)application:(NSApplication *)app openFile:(NSString *)filename
{
	NSLog(@"importing %@", filename);
	return YES;
}

-(void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	NSLog(@"got files:%@", filenames);
	[sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
}

//a timer runs while active that will autosave coredata changes periodically
-(void)applicationWillBecomeActive:(NSNotification *)note
{
	self.autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(autoSaveChanges) userInfo:nil repeats:YES];
}

//invalidate autosave timer and do an autosave
-(void)applicationWillResignActive:(NSNotification *)note
{
	[self.autosaveTimer invalidate];
	self.autosaveTimer=nil;
	[self autoSaveChanges];
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	return NO;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([[menuItem representedObject] isKindOfClass:[Theme class]]) {
		if ([[ThemeEngine sharedInstance] currentTheme] == menuItem.representedObject)
			menuItem.state = NSOnState;
		else
			menuItem.state = NSOffState;
		return YES;
	} else if (menuItem.action == @selector(showPreferences:))
		return YES;
	return NO;
}

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	if ([item action] == @selector(doLogOut:))
		return self.loggedIn;

	return YES;
}

-(void)windowWillClose:(NSNotification*)note
{
	if ([note object] == self.mainWindowController.window) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self doLogOut:nil];
		});
		[[NSNotificationCenter defaultCenter] removeObserver:self 
														name:NSWindowWillCloseNotification 
													  object:self.mainWindowController.window];
	}
}

-(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if ([url hasPrefix:@"db-:"]) {
		[NSApp activate];
	}
}

#pragma mark - actions

-(IBAction)doLogOut:(id)sender
{
	[self.mainWindowController close];
	self.mainWindowController=nil;
	self.loggedIn=NO;
	[[Rc2Server sharedInstance] logout];
	[self presentLoginPanel];
}

-(IBAction)showPreferences:(id)sender
{
	if (nil == self.prefsController) {
		RCMGeneralPrefs *gen = [[RCMGeneralPrefs alloc] initWithNibName:@"GeneralPrefs" bundle:nil];
		RCMFontPrefs *fonts = [[RCMFontPrefs alloc] initWithNibName:@"FontsPrefs" bundle:nil];
		self.prefsController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[gen,fonts] title:@"Preferences"];
	}
	[self.prefsController showWindow:self];
}

#pragma mark - meat & potatoes

-(void)displayPdfFile:(RCFile*)file
{
	RCMPDFViewController *pvc = [[RCMPDFViewController alloc] init];
	[pvc view]; //load from nib
	[pvc loadPdfFile:file];
	[self showViewController:pvc];
}

-(void)popCurrentViewController
{
	[self.mainWindowController.navController popViewControllerAnimated:YES];
}

-(void)showViewController:(AMViewController*)controller
{
	[self.mainWindowController.navController pushViewController:controller animated:YES];
}

-(void)presentLoginPanel
{
	__weak AppDelegate *blockSelf = self;
	self.loginController = [[MCLoginController alloc] init];
	[self.loginController promptForLoginWithCompletionBlock:^{
		blockSelf.loginController=nil;
		[blockSelf handleSucessfulLogin];
	}];
	if (__firstLogin && [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoLogin"])
		[self.loginController doLogin:self];
	__firstLogin=NO;
}

-(void)handleSucessfulLogin
{
	self.loggedIn = YES;
	[[NSUserDefaults standardUserDefaults] setObject:[Rc2Server sharedInstance].currentLogin forKey:kPref_LastLoginString];
	self.mainWindowController = [[MCMainWindowController alloc] init];
	[self.mainWindowController.window makeKeyAndOrderFront:self];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowWillClose:) 
												 name:NSWindowWillCloseNotification 
											   object:self.mainWindowController.window];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPref_StartInFullScreen]) {
		[self.mainWindowController.window toggleFullScreen:self];
	}
}

-(void)displayTextInExternalEditor:(NSString*)text
{
	if (nil == self.bbedit)
		self.bbedit = [SBApplication applicationWithBundleIdentifier:@"com.barebones.bbedit"];
	BBEditTextDocument *doc = [[[self.bbedit classForScriptingClass:@"text document"] alloc] init];
	[self.bbedit.textDocuments addObject:doc];
	doc.contents = text;
	[self.bbedit activate];
}

-(void)autoSaveChanges
{
	if (![NSThread isMainThread]) {
		Rc2LogError(@"autoSaveChanges called from background thread");
		return;
	}
	NSManagedObjectContext *moc = [self managedObjectContext:NO];
	if (moc.hasChanges) {
		NSError *err=nil;
		if (![moc save:&err]) {
			Rc2LogError(@"failed to save moc changes: %@", err);
		}
	}
}

-(void)selectTheme:(NSMenuItem*)item
{
	[[ThemeEngine sharedInstance] setCurrentTheme:item.representedObject];
}

-(void)setupThemeMenu
{
	NSMenuItem *viewItem = [[NSApp mainMenu] itemWithTag:kMenuView];
	ZAssert(viewItem, @"failed to find view menu");
	NSMenuItem *titem = [[viewItem submenu] itemWithTag:2112];
	ZAssert(titem, @"failed to find theme submenu");
	NSMenu *menu = [titem submenu];
	[menu removeAllItems];
	if (nil == menu) {
		menu = [[NSMenu alloc] initWithTitle:@"Theme"];
		[titem setMenu:menu];
	}
	for (Theme *theme in [[ThemeEngine sharedInstance] allThemes]) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:theme.name action:@selector(selectTheme:) keyEquivalent:@""];
		item.representedObject = theme;
		[menu addItem:item];
	}
}

#pragma mark - hockey app

-(NSString*)crashReportUserID
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kPref_LastLoginString];
}

#pragma mark - core data

/**
	Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Rc²" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory
{
	return [NSURL fileURLWithPath:[NSApp thisApplicationsSupportFolder]];
}

-(NSManagedObjectModel *)managedObjectModel
{
	if (__managedObjectModel)
		return __managedObjectModel;
	
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Rc2" withExtension:@"momd"];
	__managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	return __managedObjectModel;
}

/**
	Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (__persistentStoreCoordinator)
		return __persistentStoreCoordinator;

	NSManagedObjectModel *mom = [self managedObjectModel];
	if (!mom) {
		Rc2LogError(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
		return nil;
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
	NSError *error = nil;
	
	NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
		
	if (!properties) {
		BOOL ok = NO;
		if ([error code] == NSFileReadNoSuchFileError) {
			ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
		}
		if (!ok) {
			[[NSApplication sharedApplication] presentError:error];
			return nil;
		}
	}
	else {
		if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
			// Customize and localize this error.
			NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
			
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
			error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
			
			[[NSApplication sharedApplication] presentError:error];
			return nil;
		}
	}
	
	NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Rc².storedata"];
	NSDictionary *options = [NSDictionary dictionaryWithObject:@YES
														forKey:NSMigratePersistentStoresAutomaticallyOption];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
LOADFILE:
	if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:options error:&error])
	{
		if (([error code] >= NSPersistentStoreIncompatibleVersionHashError) &&
			([error code] <= NSEntityMigrationPolicyError))
		{
			//migration failed. we'll just nuke the store and try again
			[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
			goto LOADFILE;
		}
		[[NSApplication sharedApplication] presentError:error];
		return nil;
	}
	__persistentStoreCoordinator = coordinator;

	return __persistentStoreCoordinator;
}

/**
	Returns the managed object context for the application (which is already
	bound to the persistent store coordinator for the application.) 
 */
-(NSManagedObjectContext *)managedObjectContext
{
	return [self managedObjectContext:YES];
}
-(NSManagedObjectContext*)managedObjectContext:(BOOL)create
{
	NSManagedObjectContext *moc = [[[NSThread currentThread] threadDictionary] objectForKey:@"appMoc"];
	if (moc || !create)
		return moc;
	//now we need to create a moc. this will require differences based on what thread we are on
	moc = [[NSManagedObjectContext alloc] init];
	[moc setPersistentStoreCoordinator: self.persistentStoreCoordinator];
	[[[NSThread	currentThread] threadDictionary] setObject:moc forKey:@"appMoc"];
	__haveMoc=YES;
	return moc;
}

/**
	Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [[self managedObjectContext] undoManager];
}

/**
	Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
	NSError *error = nil;
	
	if (![[self managedObjectContext] commitEditing]) {
		Rc2LogWarn(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
	}

	if (![[self managedObjectContext] save:&error]) {
		[[NSApplication sharedApplication] presentError:error];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	if (self.isFullScreen)
		[defs setBool:YES forKey:kPref_StartInFullScreen];
	else
		[defs removeObjectForKey:kPref_StartInFullScreen];
	[defs synchronize];
	[self.mainWindowController close];
	
	// Save changes in the application's managed object context before the application terminates.
	if (!__haveMoc) {
		return NSTerminateNow;
	}

	if (![[self managedObjectContext] commitEditing]) {
		Rc2LogWarn(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
		return NSTerminateCancel;
	}

	if (![[self managedObjectContext] hasChanges]) {
		return NSTerminateNow;
	}

	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {

		// Customize this code block to include application-specific recovery steps.              
		BOOL result = [sender presentError:error];
		if (result) {
			return NSTerminateCancel;
		}

		NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
		NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
		NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
		NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:question];
		[alert setInformativeText:info];
		[alert addButtonWithTitle:quitButton];
		[alert addButtonWithTitle:cancelButton];

		NSInteger answer = [alert runModal];
		
		if (answer == NSAlertAlternateReturn) {
			return NSTerminateCancel;
		}
	}

	return NSTerminateNow;
}

@end
