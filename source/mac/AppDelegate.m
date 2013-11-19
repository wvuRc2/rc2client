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
-(void)autoSaveChanges;
-(void)presentLoginPanel;
-(void)windowWillClose:(NSNotification*)note;
@end

@implementation AppDelegate

-(void)showMainApplicationWindow
{
	[self presentLoginPanel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	__firstLogin=YES;
	[[VyanaLogger sharedInstance] startLogging];
	[[VyanaLogger sharedInstance] setLogLevel:LOG_LEVEL_INFO forKey:@"rc2"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"MacDefaults" withExtension:@"plist"];
	NSDictionary *defs = [NSDictionary dictionaryWithContentsOfURL:url];
	ZAssert(defs, @"failed toload default defaults");
	url = [[NSBundle mainBundle] URLForResource:@"CommonDefaults" withExtension:@"plist"];
	NSMutableDictionary *allDefs = [NSMutableDictionary dictionaryWithContentsOfURL:url];
	ZAssert(allDefs, @"failed to load common defaults");
	[allDefs addEntriesFromDictionary:defs];
	[defaults registerDefaults:allDefs];

#if DEBUG
	//if F-Script is available, install in menu bar
	Class fscriptClz = NSClassFromString(@"FScriptMenuItem");
	if (fscriptClz)
		[[NSApp mainMenu] addItem:[[fscriptClz alloc] init]];
	[self showMainApplicationWindow];
#else
//	[[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"f4225a0ff7ed8fe53eb30f4a29a21689" companyName:@"WVU Statistics Dept" crashReportManagerDelegate:self];
//	[[BITHockeyManager sharedHockeyManager] setExceptionInterceptionEnabled:!YES];
//	[[BITHockeyManager sharedHockeyManager] startManager];
	[self showMainApplicationWindow];
#endif

	[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Rc2.sqlite"];
	[MagicalRecord setShouldDeleteStoreOnModelMismatch:YES];
	
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	if (self.isFullScreen)
		[defs setBool:YES forKey:kPref_StartInFullScreen];
	else
		[defs removeObjectForKey:kPref_StartInFullScreen];
	[defs synchronize];
	[self.mainWindowController close];
	[MagicalRecord cleanUp];
	return NSTerminateNow;
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
	NSManagedObjectContext *moc = [NSManagedObjectContext MR_defaultContext];
	if (moc.hasChanges) {
		[moc MR_saveToPersistentStoreAndWait];
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

-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [[NSManagedObjectContext MR_defaultContext] undoManager];
}

@end
