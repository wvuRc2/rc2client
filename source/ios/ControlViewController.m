//
//  ControlViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "ControlViewController.h"
#import "RCSession.h"
#import "ControllerUserCell.h"

@interface ControlViewController()
@end

@implementation ControlViewController

- (id)init
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
	}
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(IBAction)changeMode:(id)sender
{
	NSString *newMode = @"share";
	if (self.modeControl.selectedSegmentIndex == 1)
		newMode = @"control";
	else if (self.modeControl.selectedSegmentIndex == 2)
		newMode = @"classroom";
	[self.session requestModeChange:newMode];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.session.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ControllerUserCell *cell = [ControllerUserCell cellForTableView:tv];
	cell.user = [self.session.users objectAtIndex:indexPath.row];
	
	return cell;
}

#pragma mark - accessors/synthesizers


-(void)setSession:(RCSession *)session
{
	if (_session == session)
		return;
	_session = session;
	__unsafe_unretained ControlViewController *bself = self;
	[self observeTarget:session keyPath:@"mode" options:0 block:^(MAKVONotification *notification)
	{
		if ([bself.session.mode isEqualToString:@"share"])
			bself.modeControl.selectedSegmentIndex = 0;
		else if ([bself.session.mode isEqualToString:@"control"])
			bself.modeControl.selectedSegmentIndex = 1;
		else if ([bself.session.mode isEqualToString:@"classroom"])
			bself.modeControl.selectedSegmentIndex = 2;
	}];
	[self observeTarget:session keyPath:@"users" options:0 block:^(MAKVONotification *notification)
	{
		[bself.userTable reloadData];
	}];
}

@end
