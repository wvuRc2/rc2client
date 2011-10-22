//
//  RCWorkspaceShare.m
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCWorkspaceShare.h"

@implementation RCWorkspaceShare

-(id)initWithDictionary:(NSDictionary*)dict workspace:(RCWorkspace*)wspace
{
	self = [super init];
	self.workspace = wspace;
	[self updateFromDictionary:dict];
	return self;
}

-(void)updateFromDictionary:(NSDictionary*)dict
{
	self.shareId = [dict objectForKey:@"id"];
	self.userId = [dict objectForKey:@"userid"];
	self.userName = [dict objectForKey:@"username"];
	self.canOpenFiles = [[dict objectForKey:@"canOpenFiles"] boolValue];
	self.canWriteFiles = [[dict objectForKey:@"canWriteFiles"] boolValue];
	self.requiresOwner = [[dict objectForKey:@"requiresOwner"] boolValue];
}

@synthesize shareId;
@synthesize userId;
@synthesize userName;
@synthesize canOpenFiles;
@synthesize canWriteFiles;
@synthesize requiresOwner;
@synthesize workspace;
@end
