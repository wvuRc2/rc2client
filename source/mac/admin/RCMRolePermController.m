//
//  RCMRolePermController.m
//  MacClient
//
//  Created by Mark Lilback on 2/6/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "RCMRolePermController.h"
#import "Rc2Server.h"

NSString *const kPermPboardType = @"edu.wvu.stat.rc2.mac.perm";

@interface RCMRolePermController()
@property (nonatomic, copy) NSArray *perms;
@property (nonatomic, copy) NSArray *roles;
@property (nonatomic, strong) NSDictionary *selectedRole;
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
	[self observeTarget:self.roleController keyPath:@"selectedObjects" selector:@selector(adjustRolePerms) userInfo:nil options:0];
	[self.permTable setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
	[self.rolePermTable registerForDraggedTypes:@[kPermPboardType]];
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
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:self.perms.count];
	for (id val in nperms) {
		id aPerm = [self.perms firstObjectWithValue:val forKey:@"id"];
		if (aPerm)
			[ma addObject:aPerm];
	}
	self.rolePermController.content = ma;
}

-(void)fetchRoles
{
	__weak RCMRolePermController *bself = self;
	[[Rc2Server sharedInstance] fetchRoles:^(BOOL success, id results) {
		NSArray *nroles = [results objectForKey:@"roles"];
		NSMutableArray *editRoles = [NSMutableArray arrayWithCapacity:nroles.count];
		for (NSDictionary *aRole in nroles) {
			NSMutableDictionary *newRole = [aRole mutableCopy];
			NSArray *nperms = [newRole objectForKey:@"permissionIds"];
			[newRole setObject:[nperms mutableCopy] forKey:@"permissionIds"];
			[editRoles addObject: newRole];
		}
		bself.roleController.content = editRoles;
		bself.roles = nroles;
	}];
}

-(void)fetchPermissions
{
	__weak RCMRolePermController *bself = self;
	[[Rc2Server sharedInstance] fetchPermissions:^(BOOL success, id results) {
		NSArray *nperms = [results objectForKey:@"perm"];
		bself.permController.content = nperms;
		bself.perms = nperms;
	}];
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
	//TODO: need to show busy status while waiting on response
	[[Rc2Server sharedInstance] addPermission:[perm objectForKey:@"id"]
									   toRole:[self.selectedRole objectForKey:@"id"]
							completionHandler:^(BOOL success, id results)
	{
		if (success) {
			[[self.selectedRole objectForKey:@"permissionIds"] addObject:[perm objectForKey:@"id"]];
			[self adjustRolePerms];
		} else {
			Rc2LogWarn(@"error adding permission:%@", results);
		}
	}];
	return YES;
}

-(void)tableView:(NSTableView*)tableView handleDeleteKey:(NSEvent*)event
{
	if (tableView != self.rolePermTable) {
		NSBeep();
		return;
	}
	//delete the selected roleperm
}
@end
