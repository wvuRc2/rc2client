//
//  ControlViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "ControlViewController.h"
#import "RCSession.h"
#import "ControllerUserCell.h"

@interface ControlViewController()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@end

@implementation ControlViewController
@synthesize session=_session;

- (id)init
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
		self.kvoTokens = [NSMutableSet set];
	}
	return self;
}

-(void)dealloc
{
	[self removeAllBlockObservers];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(IBAction)changeMode:(id)sender
{
	NSLog(@"change mode:%d", self.modeControl.selectedSegmentIndex);
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
	__unsafe_unretained ControlViewController *blockSelf = self;
	[self.kvoTokens addObject:[session addObserverForKeyPath:@"mode" 
													 onQueue:[NSOperationQueue mainQueue] 
														task:^(id obj, NSDictionary *change)
	{
		if ([blockSelf.session.mode isEqualToString:@"share"])
			blockSelf.modeControl.selectedSegmentIndex = 0;
		else if ([blockSelf.session.mode isEqualToString:@"control"])
			blockSelf.modeControl.selectedSegmentIndex = 1;
		else if ([blockSelf.session.mode isEqualToString:@"classroom"])
			blockSelf.modeControl.selectedSegmentIndex = 2;
	}]];
	[self.kvoTokens addObject:[session addObserverForKeyPath:@"users" 
													 onQueue:[NSOperationQueue mainQueue] 
														task:^(id obj, NSDictionary *change)
	{
		[blockSelf.userTable reloadData];
	}]];
}

@synthesize modeControl;
@synthesize kvoTokens;
@synthesize userTable;
@end
