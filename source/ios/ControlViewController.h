//
//  ControlViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCSession;

@interface ControlViewController : UIViewController
@property (nonatomic, weak) IBOutlet UISegmentedControl *modeControl;
@property (nonatomic, weak) IBOutlet UITableView *userTable;
@property (nonatomic, strong) RCSession *session;
-(IBAction)changeMode:(id)sender;
@end
