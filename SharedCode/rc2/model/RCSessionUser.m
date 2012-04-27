//
//  RCSessionUser.m
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCSessionUser.h"

@implementation RCSessionUser

- (id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.displayName = [dict objectForKey:@"displayName"];
		self.name = [dict objectForKey:@"name"];
		self.login = [dict objectForKey:@"login"];
		self.userId = [dict objectForKey:@"id"];
		self.sid = [dict objectForKey:@"sid"];
		self.master = [[dict objectForKey:@"master"] boolValue];
		self.control = [[dict objectForKey:@"control"] boolValue];
	}
	return self;
}

@synthesize displayName;
@synthesize name;
@synthesize login;
@synthesize master;
@synthesize userId;
@synthesize sid;
@synthesize control;
@synthesize handRaised;
@end
