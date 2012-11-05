//
//  Rc2AppDelegate.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BWHockeyManager.h"

@class SessionViewController;
@class RCFile;
@class RCWorkspace;

@interface Rc2AppDelegate : UIResponder <UIApplicationDelegate, BWHockeyManagerDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) SessionViewController *sessionController;
@property (nonatomic, copy) BasicBlock dropboxCompletionBlock;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(IBAction)showMessages:(id)sender;
-(IBAction)showWelcome:(id)sender;
-(IBAction)showWorkspaces:(id)sender;
-(IBAction)showGrading:(id)sender;
-(IBAction)logout:(id)sender;

-(void)promptForLogin;
-(void)openSession:(RCWorkspace*)workspace;
-(void)startSession:(RCFile*)initialFile;
-(IBAction)endSession:(id)sender;
-(void)displayPdfFile:(RCFile*)file;

-(NSURL *)applicationDocumentsDirectory;
@end
