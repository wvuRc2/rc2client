//
//  AppDelegate.m
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "AppDelegate.h"
#import "MacLoginController.h"
#import "MacMainWindowController.h"
#import "Rc2Server.h"
#import "SessionViewController.h"
#import "RCSession.h"

@interface AppDelegate() {
	BOOL __haveMoc;
	BOOL __firstLogin;
}
@property (strong) MacLoginController *loginController;
@property (readwrite, strong, nonatomic) MacMainWindowController *mainWindowController;
@property (nonatomic, strong) NSTimer *autosaveTimer;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, strong) NSMutableSet *sessionControllers;
@property (nonatomic, strong) NSMutableSet *windowControllers;
-(void)handleSucessfulLogin;
-(NSManagedObjectContext*)managedObjectContext:(BOOL)create;
-(void)autoSaveChanges;
-(void)presentLoginPanel;
-(void)windowWillClose:(NSNotification*)note;
@end

@implementation AppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize mainWindowController = _mainWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	__firstLogin=YES;
	self.openSessions = [NSMutableArray array];
	self.sessionControllers = [NSMutableSet set];
	self.windowControllers = [NSMutableSet set];
	[self presentLoginPanel];
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
	for (RCSession *session in self.openSessions) {
		if (session.workspace == wspace)
			return session;
	}
	//TODO: need to implement limit on how many sessions can be open
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readperm",
																	[NSNumber numberWithBool:YES], @"writeperm",
																	nil];
	RCSession *s = [[RCSession alloc] initWithWorkspace:wspace serverResponse:dict];
	[self.openSessions addObject:s];
	return s;
}

-(SessionViewController*)viewControllerForSession:(RCSession*)session create:(BOOL)create
{
	for (SessionViewController *aController in self.sessionControllers) {
		if (aController.session == session)
			return aController;
	}
	if (create) {
		SessionViewController *svc = [[SessionViewController alloc] initWithSession:session];
		[self.sessionControllers addObject:svc];
		return svc;
	}
	return nil;
}

-(void)closeSessionViewController:(SessionViewController*)svc
{
	RCSession *session = svc.session;
	[self.sessionControllers removeObject:svc];
	[self willChangeValueForKey:@"openSessions"];
	[self.openSessions removeObject:session];
	[self didChangeValueForKey:@"openSessions"];
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

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
@synthesize openSessions;
@synthesize sessionControllers;
@synthesize windowControllers;
@end
