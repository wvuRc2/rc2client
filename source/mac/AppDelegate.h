//
//  AppDelegate.h
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCMainWindowController;
@class MCSessionViewController;
@class RCSession;
@class RCWorkspace;
@class RCFile;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) MCMainWindowController *mainWindowController;
@property (nonatomic, readonly) BOOL loggedIn;
@property (nonatomic, readonly) BOOL isFullScreen;

-(void)showViewController:(AMViewController*)controller;
-(void)displayPdfFile:(RCFile*)file;
-(void)popCurrentViewController;

-(IBAction)doLogOut:(id)sender;

- (IBAction)saveAction:(id)sender;
-(void)displayTextInExternalEditor:(NSString*)text;
@end
