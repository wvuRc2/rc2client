//
//  RCUser.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCUser.h"

@interface RCUser()
@property (nonatomic, strong, readwrite) NSNumber *userId;
@property (nonatomic, strong) NSDictionary *origDict;
@end

@implementation RCUser
@synthesize origDict;
@synthesize userId;
@synthesize isDirty;
@synthesize isAdmin=__isAdmin;
@synthesize name=__name;
@synthesize email=__email;
@synthesize login=__login;
@synthesize roleIds=_roleIds;
@synthesize roles=_roles;

-(id)init
{
	self = [super init];
	self.origDict = [NSDictionary dictionary];
	return self;
}

-(id)initWithDictionary:(NSDictionary*)dict allRoles:(NSArray*)allRoles
{
	self = [super init];
	self.origDict = dict;
	self.userId = [dict objectForKey:@"id"];
	self.login = [dict objectForKey:@"login"];
	self.name = [dict objectForKey:@"name"];
	self.email = [dict objectForKey:@"email"];
	self.isAdmin = [[dict objectForKey:@"isadmin"] boolValue];
	self.roleIds = [dict objectForKey:@"roleIds"];
	NSMutableArray *roleArray = [NSMutableArray arrayWithCapacity:allRoles.count];
	for (NSDictionary *roleDict in allRoles) {
		NSMutableDictionary *md = [NSMutableDictionary dictionary];
		[md setObject:[roleDict objectForKey:@"shortname"] forKey:@"name"];
		if ([self.roleIds containsObject:[roleDict objectForKey:@"id"]])
			[md setObject:[NSNumber numberWithBool:YES] forKey:@"have"];
		else
			[md setObject:[NSNumber numberWithBool:NO] forKey:@"have"];
		[roleArray addObject:md];
	}
	NSLog(@"roleArray = %@", roleArray);
	self.roles = roleArray;
	return self;
}

-(BOOL)isDirty
{
	return [self.name isEqualToString:[self.origDict objectForKey:@"name"]] &&
		[self.email isEqualToString:[self.origDict objectForKey:@"email"]] &&
		[self.login isEqualToString:[self.origDict objectForKey:@"login"]] &&
		self.isAdmin == [[self.origDict objectForKey:@"isadmin"] boolValue];
}

-(BOOL)existsOnServer
{
	return nil != self.userId;
}

@end

