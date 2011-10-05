//
//  AppDelegate.h
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MacMainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) MacMainWindowController *mainWindowController;
@property (nonatomic, readonly) BOOL loggedIn;
@property (nonatomic, strong) NSMutableArray *openSessions;

-(IBAction)doLogOut:(id)sender;

- (IBAction)saveAction:(id)sender;

@end
