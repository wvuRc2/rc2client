//
//  AppDelegate.h
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MacMainWindowController;
@class MacSessionViewController;
@class RCSession;
@class RCWorkspace;
@class RCFile;

@interface AppDelegate : NSObject <NSApplicationDelegate,NSToolbarDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) MacMainWindowController *mainWindowController;
@property (nonatomic, readonly) BOOL loggedIn;
@property (nonatomic, readonly) BOOL isFullScreen;

-(RCSession*)sessionForWorkspace:(RCWorkspace*)wspace;
-(MacSessionViewController*)viewControllerForSession:(RCSession*)session create:(BOOL)create;
//closes both sessionviewcontroller and session
-(void)closeSessionViewController:(MacSessionViewController*)svc;

-(void)addWindowController:(NSWindowController*)controller;
-(void)removeWindowController:(NSWindowController*)controller;

-(void)showViewController:(AMViewController*)controller;
-(void)displayPdfFile:(RCFile*)file;

-(IBAction)doLogOut:(id)sender;

- (IBAction)saveAction:(id)sender;
-(void)displayTextInExternalEditor:(NSString*)text;
@end
