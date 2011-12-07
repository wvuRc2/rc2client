//
//  AppDelegate.m
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "AppDelegate.h"
#import "RCMAppConstants.h"
#import "MacLoginController.h"
#import "MacMainWindowController.h"
#import "Rc2Server.h"
#import "MacSessionViewController.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCMacToolbarItem.h"
#import "ASIHTTPRequest.h"
#import "BBEdit.h"

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
//@property (nonatomic, strong) NSMutableSet *sessionControllers;
@property (nonatomic, strong) NSMutableSet *windowControllers;
//following is only used while operating in the __fileCacheQueue
@property (nonatomic, strong) NSMutableSet *fileCacheWorkspacesInQueue;
@property (nonatomic, strong) RCSession *currentSession;
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	__firstLogin=YES;
	self.windowControllers = [NSMutableSet set];
	[self presentLoginPanel];
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
	for (NSWindowController *wc in self.windowControllers)
		[wc close];
	[self.windowControllers removeAllObjects];
	self.loggedIn=NO;
	[self presentLoginPanel];
}

#pragma mark - meat & potatoes

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
				NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [rc2 baseUrl],
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

-(void)addWindowController:(NSWindowController*)controller
{
	[self.windowControllers addObject:controller];
}

-(void)removeWindowController:(NSWindowController*)controller
{
	[self.windowControllers removeObject:controller];
}

-(RCSession*)sessionForWorkspace:(RCWorkspace *)wspace
{
	if (self.currentSession.workspace == wspace)
		return self.currentSession;
	//TODO: need to implement limit on how many sessions can be open
	self.currentSession = [[RCSession alloc] initWithWorkspace:wspace serverResponse:nil];
	return self.currentSession;
}

-(MacSessionViewController*)viewControllerForSession:(RCSession*)session create:(BOOL)create
{
	if (create) {
		MacSessionViewController *svc = [[MacSessionViewController alloc] initWithSession:session];
		return svc;
	}
	return nil;
}

-(void)closeSessionViewController:(MacSessionViewController*)svc
{
	RCSession *session = svc.session;
	[session closeWebSocket];
	self.currentSession=nil;
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

#pragma mark - toolbar delegate

-(NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier 
	willBeInsertedIntoToolbar:(BOOL)flag
{
	RCMacToolbarItem *ti = [[RCMacToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	if ([itemIdentifier isEqualToString:RCMToolbarItem_Add]) {
		if ([[toolbar identifier] isEqualToString:@"sessionwindow"])
			ti.toolTip = @"Add a file";
		else
			ti.toolTip = @"Add a workspace/folder";
		ti.image = [NSImage imageNamed:NSImageNameAddTemplate];
	} else if ([itemIdentifier isEqualToString:RCMToolbarItem_Remove]) {
		if ([[toolbar identifier] isEqualToString:@"sessionwindow"])
			ti.toolTip = @"Remove selected file";
		else
			ti.toolTip = @"Remove selected workspace/folder";
		ti.image = [NSImage imageNamed:NSImageNameRemoveTemplate];
	} else if ([itemIdentifier isEqualToString:RCMToolbarItem_Back]) {
		ti.toolTip = @"Return to workspaces";
		ti.action = @selector(doBackToMainView:);
		ti.image = [NSImage imageNamed:NSImageNameLeftFacingTriangleTemplate];
	} else if ([itemIdentifier isEqualToString:RCMToolbarItem_OpenSession]) {
		ti.toolTip = @"Open session to the selected workspace. Option-click to open in a new window.";
		ti.action = @selector(doOpenSession:);
		ti.image = [NSImage imageNamed:@"RLogo"];
	} else if ([itemIdentifier isEqualToString:RCMToolbarItem_Files]) {
		ti.toolTip = @"Show/Hide file list";
		ti.action = @selector(toggleFileList:);
		ti.image = [NSImage imageNamed:NSImageNameListViewTemplate];
	}
	return ti;
}

-(NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:RCMToolbarItem_Files, RCMToolbarItem_OpenSession,
			RCMToolbarItem_Back, RCMToolbarItem_Remove, RCMToolbarItem_Add, nil];
}

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	if ([[toolbar identifier] isEqualToString:@"sessionwindow"]) {
		return [NSArray arrayWithObjects:RCMToolbarItem_Back, RCMToolbarItem_Files,
				RCMToolbarItem_Add, RCMToolbarItem_Remove, nil];
	} else {
		return [NSArray arrayWithObjects:RCMToolbarItem_Back,RCMToolbarItem_Add, RCMToolbarItem_Remove, 
				RCMToolbarItem_OpenSession, RCMToolbarItem_Files, nil];
	}
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
	if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:options error:&error])
	{
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
	for (NSWindowController *wc in self.windowControllers)
		[wc close];
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
@synthesize currentSession;
//@synthesize sessionControllers;
@synthesize windowControllers;
@synthesize fileCacheWorkspacesInQueue;
@synthesize bbedit;
@synthesize isFullScreen;
@end
