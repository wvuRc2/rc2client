//
//  VariableDetailViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCVariable;

@interface VariableDetailViewController : UITableViewController
@property (nonatomic, strong) RCVariable *variable;
@end
