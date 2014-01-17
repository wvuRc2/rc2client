//
//  RCUser.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCUser.h"

@interface RCUser()
@property (nonatomic, strong, readwrite) NSNumber *userId;
@property (nonatomic, strong) NSDictionary *origDict;
@end

@implementation RCUser

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
	self.firstname = [dict objectForKey:@"firstname"];
	self.lastname = [dict objectForKey:@"lastname"];
	self.email = [dict objectForKey:@"email"];
	self.ldapLogin = [dict objectForKey:@"ldaplogin"];
	self.ldapServerId = [dict valueForKeyPath:@"ldapServer.id"];
	self.isAdmin = [[dict objectForKey:@"isadmin"] boolValue];
	self.roleIds = [dict objectForKey:@"roleIds"];
	NSMutableArray *roleArray = [NSMutableArray arrayWithCapacity:allRoles.count];
	for (NSDictionary *roleDict in allRoles) {
		NSMutableDictionary *md = [NSMutableDictionary dictionary];
		[md setObject:[roleDict objectForKey:@"shortname"] forKey:@"name"];
		[md setObject:[roleDict objectForKey:@"id"] forKey:@"id"];
		if ([self.roleIds containsObject:[roleDict objectForKey:@"id"]])
			[md setObject:@YES forKey:@"have"];
		else
			[md setObject:@NO forKey:@"have"];
		[md setObject:[md objectForKey:@"have"] forKey:@"savedHave"];
		[roleArray addObject:md];
	}
	self.roles = roleArray;
	return self;
}

-(BOOL)isDirty
{
	return [self.firstname isEqualToString:[self.origDict objectForKey:@"firstname"]] &&
		[self.lastname isEqualToString:[self.origDict objectForKey:@"lastname"]] &&
		[self.email isEqualToString:[self.origDict objectForKey:@"email"]] &&
		[self.login isEqualToString:[self.origDict objectForKey:@"login"]] &&
		self.isAdmin == [[self.origDict objectForKey:@"isadmin"] boolValue];
}

-(BOOL)existsOnServer
{
	return nil != self.userId;
}

@end

