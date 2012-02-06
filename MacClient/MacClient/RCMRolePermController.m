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

@interface RCMRolePermController()
@property (nonatomic, copy) NSArray *perms;
@property (nonatomic, copy) NSArray *roles;
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
}

-(void)adjustRolePerms
{
	NSArray *selObjs = [self.roleController selectedObjects];
	if (selObjs.count < 1) {
		self.rolePermController.content=nil;
		return;
	}
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

@synthesize permTable;
@synthesize permController;
@synthesize roleTable;
@synthesize roleController;
@synthesize rolePermController;
@synthesize perms;
@synthesize roles;
@synthesize rpKey;
@end
