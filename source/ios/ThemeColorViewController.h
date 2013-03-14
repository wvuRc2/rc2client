//
//  ThemeColorViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ThemeColorViewController : UIViewController
@property (copy) BasicBlock completionBlock;
-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;
@end
