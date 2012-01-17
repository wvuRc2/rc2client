//
//  RCMSessionUserController.m
//  MacClient
//
//  Created by Mark Lilback on 1/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMSessionUserController.h"
#import "RCSession.h"

@interface RCMSessionUserController()
@property (nonatomic, strong) NSMutableArray *users;
@end

@implementation RCMSessionUserController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.users = [[NSMutableArray alloc] init];
	}
	return self;
}

#pragma mark - actions

-(IBAction)refreshList:(id)sender
{
	[self.session requestUserList];
}

#pragma mark - meat & potatos

-(void)userJoined:(NSDictionary*)dict
{
	[self.users removeAllObjects];
	[self.users addObjectsFromArray:[dict valueForKeyPath:@"session.users"]];
	[self.userTableView reloadData];
}

-(void)userLeft:(NSDictionary*)dict
{
	[self.users removeAllObjects];
	[self.users addObjectsFromArray:[dict valueForKeyPath:@"session.users"]];
	[self.userTableView reloadData];
}

-(void)userListUpdated:(NSDictionary*)dict
{
	[self.users removeAllObjects];
	[self.users addObjectsFromArray:[dict valueForKeyPath:@"data.users"]];
	[self.userTableView reloadData];
}

#pragma mark - table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.users count];
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *view = [tableView makeViewWithIdentifier:@"userCell" owner:nil];
	view.objectValue = [self.users objectAtIndex:row];
	return view;
}

@synthesize session;
@synthesize users;
@synthesize userTableView;
@end
