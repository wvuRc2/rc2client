//
//  ProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ProjectViewController.h"
#import "ProjectCell.h"
#import "Rc2Server.h"
#import "ThemeEngine.h"
#import "ProjectViewLayout.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "Rc2AppDelegate.h"
#import "MAKVONotificationCenter.h"
#import "MBProgressHUD.h"

@interface ProjectViewController ()
@end

@implementation ProjectViewController

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"Rc2 Projects", @"");
}

-(void)loginStatusChanged
{
	[super loginStatusChanged];
	self.navigationItem.title = NSLocalizedString(@"Rc2 Projects", @"");
}

@end
