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
#import "ASIFormDataRequest.h"
#import <Vyana/AMBlockUtils.h>
#import <Vyana/NSApplication+AMExtensions.h>

@interface RCMUserAdminController() {
	BOOL _updatingRole;
}
@property (nonatomic, strong) id lastSelectedUserRole;
@property (nonatomic, strong) id checkToken;
@property (nonatomic, copy) NSArray *users;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, strong) RCMEditUserController *editController;
@property (nonatomic, strong) IBOutlet NSWindow *passwordWindow;
@property (nonatomic, copy) NSString *passChange1;
@property (nonatomic, copy) NSString *passChange2;
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
	ASIHTTPRequest *request = [[Rc2Server sharedInstance] requestWithRelativeURL:@"role"];
	__unsafe_unretained ASIHTTPRequest *req = request;
	[request setCompletionBlock:^{
		NSDictionary *rsp = [[NSString stringWithUTF8Data:[req responseData]] JSONValue];
		self.roles = [rsp objectForKey:@"roles"];
	}];
	[req startAsynchronous];
	__unsafe_unretained RCMUserAdminController *blockSelf = self;
	self.checkToken = [self.detailController addObserverForKeyPath:@"selection.have" task:^(id obj, NSDictionary *dict)
	{
		if (blockSelf->_updatingRole)
			return;
		NSMutableDictionary *roleDict = [[obj selectedObjects] firstObject];
		BOOL needUpdate=NO;
		if (roleDict && roleDict == blockSelf.lastSelectedUserRole) {
			needUpdate = roleDict && ![[roleDict objectForKey:@"have"] isEqual:[roleDict objectForKey:@"savedHave"]];
		} else {
			blockSelf.lastSelectedUserRole = roleDict;
			needUpdate = roleDict && ![[roleDict objectForKey:@"have"] isEqual:[roleDict objectForKey:@"savedHave"]];
		}
		if (needUpdate)
			[blockSelf toggleRole:roleDict];
	}];
}

#pragma mark - meat & potatos

-(void)toggleRole:(NSMutableDictionary*)roleDict
{
	ASIFormDataRequest *request = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"/admin/user?role"];
	__unsafe_unretained ASIFormDataRequest *req = request;
	NSNumber *userid = [self.userController.selectedObjects.firstObject userId];
	NSNumber *roleid = [roleDict objectForKey:@"id"];
	ZAssert(roleid && userid, @"invalid role/user");
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:userid, @"userid", roleid, @"roleid", nil];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[params JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setCompletionBlock:^{
		NSDictionary *rsp = [[NSString stringWithUTF8Data:[req responseData]] JSONValue];
		if ([[rsp objectForKey:@"status"] intValue] == 0) {
			[roleDict setObject:[rsp objectForKey:@"havePerm"] forKey:@"have"];
			[roleDict setObject:[rsp objectForKey:@"havePerm"] forKey:@"savedHave"];
		} else {
			NSLog(@"server gave error for toggle");
		}
		_updatingRole = NO;
	}];
	_updatingRole = YES;
	[req startAsynchronous];
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
	//send the new user command to the server
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"admin/user"];
	__block ASIFormDataRequest *request = req;
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:pass, @"pass", user.email, @"email", 
						  user.login, @"login", user.name, @"name", nil];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setCompletionBlock:^{
		NSDictionary *rsp = [[NSString stringWithUTF8Data:[request responseData]] JSONValue];
		if ([[rsp objectForKey:@"status"] intValue] != 0) {
			NSError *err = [NSError errorWithDomain:@"Rc2" code:1 userInfo:[NSDictionary dictionaryWithObject:[rsp objectForKey:@"message"] forKey:NSLocalizedDescriptionKey]];
			[NSApp presentError:err];
		} else {
			//worked. add that user to our display
			RCUser *newUser = [[RCUser alloc] initWithDictionary:[rsp objectForKey:@"user"] allRoles:self.roles];
			if (self.users)
				self.users = [self.users arrayByAddingObject:newUser];
			else
				self.users = [NSArray arrayWithObject:newUser];
			[self.resultsTable reloadData];
		}
	}];
	[req startAsynchronous];
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
	ASIFormDataRequest *request = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"user"];
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
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", ss, @"value", nil];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
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

#pragma mark - synthesizers

@synthesize resultsTable;
@synthesize searchField;
@synthesize users=_users;
@synthesize searchesNames;
@synthesize searchesEmails;
@synthesize searchesLogins;
@synthesize editController;
@synthesize roles=_roles;
@synthesize userController;
@synthesize detailController;
@synthesize checkToken=_checkToken;
@synthesize lastSelectedUserRole=_lastSelectedUserRole;
@synthesize passChange1;
@synthesize passChange2;
@synthesize passwordWindow;
@end
