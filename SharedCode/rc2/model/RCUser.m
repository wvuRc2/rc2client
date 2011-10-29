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

-(id)init
{
	self = [super init];
	self.origDict = [NSDictionary dictionary];
	return self;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	self.origDict = dict;
	self.userId = [dict objectForKey:@"id"];
	self.login = [dict objectForKey:@"login"];
	self.name = [dict objectForKey:@"name"];
	self.email = [dict objectForKey:@"email"];
	self.isAdmin = [[dict objectForKey:@"isadmin"] boolValue];
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

