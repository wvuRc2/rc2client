//
//  BaseVariableViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 11/11/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCVariable;
@class RCSession;

@interface BaseVariableViewController : UITableViewController
@property (nonatomic, strong) RCSession *session;
-(void)showVariableDetails:(RCVariable*)var;
@end
