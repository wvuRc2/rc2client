//
//  AppDelegate.m
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "AppDelegate.h"
#import "RCMAppConstants.h"
#import "MacLoginController.h"
#import "MacMainWindowController.h"
#import "Rc2Server.h"
#import "MacSessionViewController.h"
#import "RCMPDFViewController.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCMacToolbarItem.h"
#import "ASIFormDataRequest.h"
#import "BBEdit.h"
#import "RCMGeneralPrefs.h"
#import "RCMFontPrefs.h"
#import <HockeySDK/CNSHockeyManager.h>

#define kPref_LastLoginString @"LastLoginString"

@interface AppDelegate() {
	dispatch_queue_t __fileCacheQueue;
	BOOL __haveMoc;
	BOOL __firstLogin;
}
@property (strong) MacLoginController *loginController;
@property (readwrite, strong, nonatomic) MacMainWindowController *mainWindowController;
@property (nonatomic, strong) NSTimer *autosaveTimer;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite) BOOL isFullScreen;
@property (nonatomic, retain) BBEditApplication *bbedit;
//following is only used while operating in the __fileCacheQueue
@property (nonatomic, strong) NSMutableSet *fileCacheWorkspacesInQueue;
-(void)handleSucessfulLogin;
-(NSManagedObjectContext*)managedObjectContext:(BOOL)create;
-(void)autoSaveChanges;
-(void)presentLoginPanel;
-(void)windowWillClose:(NSNotification*)note;
-(void)updateFileCache:(NSNotification*)note;
@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize mainWindowController = _mainWindowController;

-(void)showMainApplicationWindow
{
	[self presentLoginPanel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[VyanaLogger sharedInstance] startLogging];
	[[VyanaLogger sharedInstance] setLogLevel:LOG_LEVEL_INFO forKey:@"rc2"];
	[[CNSHockeyManager sharedHockeyManager] configureWithIdentifier:@"f4225a0ff7ed8fe53eb30f4a29a21689" delegate:self];
	
	__firstLogin=YES;
	NSString *fileCache = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"files"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileCache])
		[[NSFileManager defaultManager] createDirectoryAtPath:fileCache withIntermediateDirectories:YES attributes:nil error:nil];
	__fileCacheQueue = dispatch_queue_create("wvu.edu.stat.Rc2.fileCache", NULL);
	self.fileCacheWorkspacesInQueue = [NSMutableSet set];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(updateFileCache:) name:RCWorkspaceFilesFetchedNotification object:nil];
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

#pragma mark - actions

-(IBAction)doLogOut:(id)sender
{
	[self.mainWindowController close];
	self.loggedIn=NO;
	[self presentLoginPanel];
}

-(IBAction)showPreferences:(id)sender
{
	AMPreferencesController *prefsController = [AMPreferencesController defaultInstance];
	if (![prefsController areModulesLoaded]) {
		//need to load our prefs modules
		[prefsController addModule:[RCMGeneralPrefs moduleWithNibName: @"GeneralPrefs"
															   bundle: nil title: @"General" identifier:@"general" imageName:nil]];
		[prefsController addModule:[RCMFontPrefs moduleWithNibName: @"FontsPrefs"
															bundle: nil title: @"Fonts" identifier:@"fonts" imageName:NSImageNameFontPanel]];
	}
	[prefsController showWindow:sender];
	[[NSArray array] objectAtIndex:21];
	NSBeep();
}

#pragma mark - meat & potatoes

-(void)handleFileImport:(NSURL*)fileUrl workspace:(RCWorkspace*)wspace completionHandler:(BasicBlock1Arg)handler
{
	[[Rc2Server sharedInstance] importFile:fileUrl workspace:wspace completionHandler:^(BOOL success, RCFile *file)
	 {
		 if (success) {
			 handler(file);
		 } else {
			 handler(nil);
		 }
	 }];
}

-(void)updateFileCache:(NSNotification*)note
{
	RCWorkspace *wspace = [note object];
	Rc2Server *rc2 = [Rc2Server sharedInstance];
	dispatch_async(__fileCacheQueue, ^{
		if ([self.fileCacheWorkspacesInQueue containsObject:wspace])
			return;
		[self.fileCacheWorkspacesInQueue addObject:wspace];
		NSFileManager *fm = [[NSFileManager alloc] init];
		NSError *err=nil;
		for (RCFile *aFile in wspace.files) {
			NSString *fpath = aFile.fileContentsPath;
			BOOL needToFetch=YES;
			if ([fm fileExistsAtPath:fpath]) {
				//TODO: do we need to update? for now we're always refetching
			}
			if (needToFetch) {
				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [rc2 baseUrl],
												   aFile.fileId]];
				ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
				req.userAgent = rc2.userAgentString;
				[req startSynchronous];
				err = req.error;
				if (err) {
					Rc2LogWarn(@"error fetching file %@ contents: %@", aFile.fileId, [err localizedDescription]);
				} else {
					[req.responseData writeToFile:fpath atomically:YES];
					aFile.fileContents = [NSString stringWithUTF8Data:req.responseData];
				}
			}
		}
		[self.fileCacheWorkspacesInQueue removeObject:wspace];
	});
}

-(void)displayPdfFile:(RCFile*)file
{
	RCMPDFViewController *pvc = [[RCMPDFViewController alloc] init];
	[pvc view]; //load from nib
	[pvc loadPdfFile:file];
	[self showViewController:pvc];
}

-(void)showViewController:(AMViewController*)controller
{
	[self.mainWindowController.navController pushViewController:controller animated:YES];
}

-(void)presentLoginPanel
{
	__weak AppDelegate *blockSelf = self;
	self.loginController = [[MacLoginController alloc] init];
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
	self.mainWindowController = [[MacMainWindowController alloc] init];
	[self.mainWindowController.window makeKeyAndOrderFront:self];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowWillClose:) 
												 name:NSWindowWillCloseNotification 
											   object:self.mainWindowController.window];
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
			NSLog(@"failed to save moc changes: %@", err);
		}
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
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
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

#pragma mark - synthesizers

@synthesize loginController;
@synthesize autosaveTimer;
@synthesize loggedIn;
@synthesize fileCacheWorkspacesInQueue;
@synthesize bbedit;
@synthesize isFullScreen;
@end
