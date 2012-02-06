//
//  RCMRolePermController.m
//  MacClient
//
//  Created by Mark Lilback on 2/6/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMRolePermController.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

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
	NSArray *perms = [[selObjs firstObject] valueForKey:@"permissionIds"];
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:perms.count];
	for (id val in perms) {
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
		NSArray *roles = [[blockReq.responseString JSONValue] objectForKey:@"roles"];
		self.roleController.content = roles;
		self.roles = roles;
	};
	[req startAsynchronous];
}

-(void)fetchPermissions
{
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:@"perm"];
	__unsafe_unretained ASIHTTPRequest *blockReq = req;
	req.completionBlock = ^{
		NSArray *perms = [blockReq.responseString JSONValue];
		self.permController.content = perms;
		self.perms = perms;
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
	
	return NO;
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
