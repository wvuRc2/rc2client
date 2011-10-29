//
//  RCMUserAdminController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMUserAdminController.h"
#import "RCMEditUserController.h"
#import "RCUser.h"
#import "Rc2Server.h"
#import "ASIFormDataRequest.h"
#import <Vyana/AMBlockUtils.h>
#import <Vyana/NSApplication+AMExtensions.h>

@interface RCMUserAdminController()
@property (nonatomic, copy) NSArray *users;
@property (nonatomic, strong) RCMEditUserController *editController;
@end

@implementation RCMUserAdminController

- (id)init
{
	if ((self = [super initWithNibName:@"RCMUserAdminController" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.searchesLogins=YES;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = menuItem.action;
	if (action == @selector(toggleSearchFilter:)) {
		if (menuItem.tag == 2000)
			menuItem.state = self.searchesNames;
		else if (menuItem.tag == 2001)
			menuItem.state = self.searchesLogins;
		else
			menuItem.state = self.searchesEmails;
		return YES;
	}
	return NO;
}

-(void)processSearchResults:(NSArray*)rsp
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:[rsp count]];
	for (NSDictionary *dict in rsp)
		[a addObject:[[RCUser alloc] initWithDictionary:dict]];
	self.users = a;
	[self.resultsTable reloadData];
}

-(IBAction)searchUsers:(id)sender
{
	NSString *ss = self.searchField.stringValue;
	if (ss.length < 1) {
		self.users = nil;
		[self.resultsTable reloadData];
		return;
	}
	ASIFormDataRequest *request = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"fd/admin/users/search"];
	__block id req = request;
	[request setCompletionBlock: ^{
		NSString *respStr = [NSString stringWithUTF8Data:[req responseData]];
		[self processSearchResults:[respStr JSONValue]];
	}];
	NSString *type = @"name";
	if (self.searchesEmails)
		type = @"email";
	else if (self.searchesLogins)
		type = @"login";
	[req setPostValue:ss forKey:@"value"];
	[req setPostValue:type forKey:@"type"];
	[req startAsynchronous];
}

-(IBAction)toggleSearchFilter:(id)sender
{
	switch ([sender tag]) {
		case 2000:
			self.searchesNames = YES;
			self.searchesEmails = NO;
			self.searchesLogins = NO;
			break;
		case 2001:
			self.searchesNames = NO;
			self.searchesEmails = NO;
			self.searchesLogins = YES;
			break;
		case 2002:
			self.searchesNames = NO;
			self.searchesEmails = YES;
			self.searchesLogins = NO;
			break;
	}
}

-(IBAction)dismissAddUser:(id)sender
{
	[NSApp endSheet:self.editController.window];
}

-(IBAction)addUser:(id)sender
{
	if (nil == self.editController) {
		self.editController = [[RCMEditUserController alloc] init];
		[self.editController window];
	}
	[NSApp beginSheet:self.editController.window modalForWindow:self.view.window 
		completionHandler:^(NSInteger returnCode)
	{
		[self.editController.window orderOut:self];
	}];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	return [self.users count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[self.users objectAtIndex:row] valueForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	self.users = [self.users sortedArrayUsingDescriptors:[tableView sortDescriptors]];
	[tableView reloadData];
}

@synthesize resultsTable;
@synthesize searchField;
@synthesize users;
@synthesize searchesNames;
@synthesize searchesEmails;
@synthesize searchesLogins;
@synthesize editController;
@end
