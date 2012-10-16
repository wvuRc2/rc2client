//
//  VariableListViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCSession;

@interface VariableListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) RCSession *session;
-(void)variablesUpdated;
@end
