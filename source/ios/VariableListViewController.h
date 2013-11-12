//
//  VariableListViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "BaseVariableViewController.h"

@class RCSession;

@interface VariableListViewController : BaseVariableViewController<UITableViewDataSource,UITableViewDelegate,UIPopoverControllerDelegate>
-(void)variablesUpdated;
@end
