//
//  WelcomeViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AbstractTopViewController.h"

@interface WelcomeViewController : AbstractTopViewController<UITableViewDataSource,UITableViewDelegate>
-(void)reloadNotifications;
@end
