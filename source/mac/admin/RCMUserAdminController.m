//
//  RCMUserAdminController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMUserAdminController.h"
#import "RCMEditUserController.h"
#import "RCUser.h"
#import "Rc2Server.h"
#import <Vyana/AMBlockUtils.h>
#import <Vyana/NSApplication+AMExtensions.h>

@interface RCMUserAdminController()
@property (nonatomic, strong) id lastSelectedUserRole;
@property (nonatomic, strong) id checkToken;
@property (nonatomic, copy) NSArray *users;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, strong) RCMEditUserController *editController;
@property (nonatomic, strong) IBOutlet NSWindow *passwordWindow;
@property (nonatomic, copy) NSString *passChange1;
@property (nonatomic, copy) NSString *passChange2;
@property (assign) BOOL updatingRole;
@end

@implementation RCMUserAdminController

- (id)init
{
	if ((self = [super initWithNibName:@"RCMUserAdminController" bundle:nil])) {
	}
	return self;
}

-(void)dealloc
{
	[self.detailController removeAllBlockObservers];
}

-(void)awakeFromNib
{
	self.searchesLogins=YES;
	__weak RCMUserAdminController *bself = self;
	[[Rc2Server sharedInstance] fetchRoles:^(BOOL success, id results) {
		bself.roles = [results objectForKey:@"roles"];
	}];
	self.checkToken = [self.detailController addObserverForKeyPath:@"selection.have" task:^(id obj, NSDictionary *dict)
	{
		if (bself.updatingRole)
			return;
		NSMutableDictionary *roleDict = [[obj selectedObjects] firstObject];
		BOOL needUpdate=NO;
		if (roleDict && roleDict == bself.lastSelectedUserRole) {
			needUpdate = roleDict && ![[roleDict objectForKey:@"have"] isEqual:[roleDict objectForKey:@"savedHave"]];
		} else {
			bself.lastSelectedUserRole = roleDict;
			needUpdate = roleDict && ![[roleDict objectForKey:@"have"] isEqual:[roleDict objectForKey:@"savedHave"]];
		}
		if (needUpdate)
			[bself toggleRole:roleDict];
	}];
}

#pragma mark - meat & potatos

-(void)toggleRole:(NSMutableDictionary*)roleDict
{
	__weak RCMUserAdminController *bself = self;
	self.updatingRole=YES;
	[[Rc2Server sharedInstance] toggleRole:[roleDict objectForKey:@"id"]
									  user:[self.userController.selectedObjects.firstObject userId]
						 completionHandler:^(BOOL success, id results)
	{
		if (success) {
			[roleDict setObject:[results objectForKey:@"havePerm"] forKey:@"have"];
			[roleDict setObject:[results objectForKey:@"havePerm"] forKey:@"savedHave"];
		} else {
			[NSAlert displayAlertWithTitle:@"Error" details:results];
			Rc2LogWarn(@"failed to toggleRole:%@", results);
		}
		bself.updatingRole=NO;
	}];
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

-(void)processSearchResults:(NSDictionary*)rsp
{
	if (![[rsp objectForKey:@"status"] intValue] == 0) {
		Rc2LogError(@"error searching users:%@", [rsp objectForKey:@"message"]);
		return;
	}
	NSArray *matches = [rsp objectForKey:@"users"];
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:[matches count]];
	for (NSDictionary *dict in matches)
		[a addObject:[[RCUser alloc] initWithDictionary:dict allRoles:self.roles]];
	self.users = a;
}

-(void)completeAddUser:(RCUser*)user password:(NSString*)pass
{
	[[Rc2Server sharedInstance] addUser:user password:pass completionHandler:^(BOOL sucess, id results)
	{
		if (!sucess) {
			[NSAlert displayAlertWithTitle:@"Error" details:results window:self.view.window];
			return;
		}
		RCUser *newUser = [[RCUser alloc] initWithDictionary:[results objectForKey:@"user"] allRoles:self.roles];
		if (self.users)
			self.users = [self.users arrayByAddingObject:newUser];
		else
			self.users = [NSArray arrayWithObject:newUser];
		[self.resultsTable reloadData];
	}];
}

#pragma mark - actions

-(IBAction)searchUsers:(id)sender
{
	NSString *ss = self.searchField.stringValue;
	if (ss.length < 1) {
		self.users = nil;
		[self.resultsTable reloadData];
		return;
	}
	NSString *type = @"name";
	if (self.searchesEmails)
		type = @"email";
	else if (self.searchesLogins)
		type = @"login";
	NSDictionary *params = @{@"type":type, @"value":ss};
	[[Rc2Server sharedInstance] searchUsers:params completionHandler:^(BOOL success, id results) {
		if (success)
			[self processSearchResults:results];
		else
			Rc2LogWarn(@"user search failed:%@", results);
	}];
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
	self.editController.theUser = [[RCUser alloc] init];
	[NSApp beginSheet:self.editController.window modalForWindow:self.view.window 
		completionHandler:^(NSInteger returnCode)
	{
		[self.editController.window orderOut:self];
		if (NSOKButton == returnCode)
			[self completeAddUser:self.editController.theUser password:self.editController.pass1Field.stringValue];
	}];
}

-(IBAction)changePassword:(id)sender
{
	/*
	self.passChange1 = nil;
	self.passChange2 = nil;
	RCUser *user = self.userController.selectedObjects.firstObject;
	ZAssert(user != nil, @"no user selected while changing password");
	[NSApp beginSheet:self.passwordWindow modalForWindow:self.view.window completionHandler:^(NSInteger rc) {
		[self.passwordWindow orderOut:self];
		if (rc == 1) {
			if (self.passChange1.length < 4 || self.passChange2.length < 4 || ![self.passChange1 isEqualToString:self.passChange2]) {
				//report error
				[NSAlert displayAlertWithTitle:@"Bad Passwords" details:@"you can pick a stronger password than that"];
				return;
			}
			//do the password change
			ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"admin/cp"];
			req.requestMethod = @"PUT";
			NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:self.passChange1, @"p", user.userId, @"uid", nil];
			[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
			[req startSynchronous];
			NSDictionary *rsp = [req.responseString JSONValue];
			if (nil == rsp) {
				[NSAlert displayAlertWithTitle:@"Error" details:@"unknown error"];
			} else if ([[rsp objectForKey:@"status"] intValue] != 0) {
				[NSAlert displayAlertWithTitle:@"Error" details:[rsp objectForKey:@"message"]];
			}
		}
	}];
	 */
}

-(IBAction)cancelPasswordChange:(id)sender
{
	[NSApp endSheet:self.passwordWindow returnCode:0];
}

-(IBAction)performPasswordChange:(id)sender
{
	[NSApp endSheet:self.passwordWindow returnCode:1];
}

#pragma mark - table view

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	self.users = [self.users sortedArrayUsingDescriptors:[tableView sortDescriptors]];
}
@end
