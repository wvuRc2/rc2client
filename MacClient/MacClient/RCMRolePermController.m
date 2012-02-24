//
//  RCMRolePermController.m
//  MacClient
//
//  Created by Mark Lilback on 2/6/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMRolePermController.h"
#import "Rc2Server.h"
#import "ASIFormDataRequest.h"

#define kPermPboardType @"edu.wvu.stat.rc2.mac.perm"

@interface RCMRolePermController()
@property (nonatomic, copy) NSArray *perms;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, strong) NSDictionary *selectedRole;
@property (nonatomic, strong) id rpKey;
-(void)fetchPermissions;
-(void)fetchRoles;
-(void)adjustRolePerms;
@end

@implementation RCMRolePermController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[self fetchPermissions];
	[self fetchRoles];
	__unsafe_unretained RCMRolePermController *blockSelf = self;
	self.rpKey = [self.roleController addObserverForKeyPath:@"selectedObjects" task:^(id obj, NSDictionary *change) {
		[blockSelf adjustRolePerms];
	}];
	[self.permTable setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
	[self.rolePermTable registerForDraggedTypes:ARRAY(kPermPboardType)];
}

-(void)adjustRolePerms
{
	NSArray *selObjs = [self.roleController selectedObjects];
	if (selObjs.count < 1) {
		self.rolePermController.content=nil;
		self.selectedRole=nil;
		return;
	}
	self.selectedRole = [selObjs firstObject];
	NSArray *nperms = [[selObjs firstObject] valueForKey:@"permissionIds"];
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:perms.count];
	for (id val in nperms) {
		id aPerm = [self.perms firstObjectWithValue:val forKey:@"id"];
		if (aPerm)
			[ma addObject:aPerm];
	}
	self.rolePermController.content = ma;
}

-(void)fetchRoles
{
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:@"role"];
	__unsafe_unretained ASIHTTPRequest *blockReq = req;
	req.completionBlock = ^{
		NSArray *nroles = [[blockReq.responseString JSONValue] objectForKey:@"roles"];
		NSMutableArray *editRoles = [NSMutableArray arrayWithCapacity:nroles.count];
		for (NSDictionary *aRole in nroles) {
			NSMutableDictionary *newRole = [aRole mutableCopy];
			NSArray *nperms = [newRole objectForKey:@"permissionIds"];
			[newRole setObject:[nperms mutableCopy] forKey:@"permissionIds"];
			[editRoles addObject: newRole];
		}
		self.roleController.content = editRoles;
		self.roles = nroles;
	};
	[req startAsynchronous];
}

-(void)fetchPermissions
{
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:@"perm"];
	__unsafe_unretained ASIHTTPRequest *blockReq = req;
	req.completionBlock = ^{
		NSArray *nperms = [blockReq.responseString JSONValue];
		self.permController.content = nperms;
		self.perms = nperms;
	};
	[req startAsynchronous];
}

#pragma mark - table view support

-(BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
	if (tableView != self.permTable)
		return NO;
	NSDictionary *perm = [self.perms objectAtIndex:[[rows firstObject] integerValue]];
	if (nil == perm)
		return NO;
	[pboard setString:[perm objectForKey:@"short"] forType:kPermPboardType];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView != self.rolePermTable)
		return NSDragOperationNone;
	if (self.selectedRole == nil)
		return NSDragOperationNone;
	NSString *permStr = [[info draggingPasteboard] stringForType:kPermPboardType];
	NSDictionary *perm = [self.perms firstObjectWithValue:permStr forKey:@"short"];
	if ([self.rolePermController.arrangedObjects containsObject:perm])
		return NSDragOperationNone;
	return NSDragOperationCopy;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row 
   dropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView != self.rolePermTable)
		return NO;
	if (self.selectedRole == nil)
		return NO;
	NSString *permStr = [[info draggingPasteboard] stringForType:kPermPboardType];
	NSDictionary *perm = [self.perms firstObjectWithValue:permStr forKey:@"short"];
	//send request to server
	NSString *msg = [NSString stringWithFormat:@"{\"action\":\"add\", \"role\":%@, \"perm\":%@}", 
					 [self.selectedRole objectForKey:@"id"], [perm objectForKey:@"id"]];
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"role"];
	[req setRequestMethod:@"PUT"];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
	[req startSynchronous];
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
	NSDictionary *dict = [respStr JSONValue];
	if ([[dict objectForKey:@"status"] intValue] == 0) {
		[[self.selectedRole objectForKey:@"permissionIds"] addObject:[perm objectForKey:@"id"]];
		[self adjustRolePerms];
		return YES;
	}
	return NO;
}

-(void)tableView:(NSTableView*)tableView handleDeleteKey:(NSEvent*)event
{
	if (tableView != self.rolePermTable) {
		NSBeep();
		return;
	}
	//delete the selected roleperm
}

@synthesize permTable;
@synthesize permController;
@synthesize roleTable;
@synthesize roleController;
@synthesize rolePermTable;
@synthesize rolePermController;
@synthesize perms;
@synthesize roles;
@synthesize rpKey;
@synthesize selectedRole;
@end
