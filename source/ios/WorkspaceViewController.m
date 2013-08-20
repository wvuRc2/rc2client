//
//  WorkspaceViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 8/15/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "WorkspaceViewController.h"
#import "RCProject.h"

@implementation WorkspaceViewController
-(void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.title = [NSLocalizedString(@"Project Title Prefix", @"") stringByAppendingString:[self.selectedProject name]];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.selectedProject.name style:UIBarButtonItemStylePlain target:nil action:nil];
}
@end
