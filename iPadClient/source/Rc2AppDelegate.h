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

@interface Rc2AppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitController;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@property (nonatomic, retain) IBOutlet DetailsViewController *detailsController;
@property (nonatomic, retain) SessionViewController *sessionController;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void)promptForLogin;
-(void)startSession;
-(IBAction)endSession:(id)sender;
-(IBAction)flipMasterView:(UIView*)otherView;
@end
