//
//  Rc2AppDelegate.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailsViewController;
@class SessionViewController;
@class MGSplitViewController;
@class RCFile;

@interface Rc2AppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, strong) IBOutlet UINavigationController *navController;
@property (nonatomic, strong) IBOutlet DetailsViewController *detailsController;
@property (nonatomic, strong) SessionViewController *sessionController;
@property (nonatomic, copy) BasicBlock dropboxCompletionBlock;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void)promptForLogin;
-(void)startSession:(RCFile*)initialFile;
-(IBAction)endSession:(id)sender;
-(IBAction)flipMasterView:(UIView*)otherView;
-(void)displayPdfFile:(RCFile*)file;

-(NSURL *)applicationDocumentsDirectory;
@end
