//
//  RCWorkspaceShare.m
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCWorkspaceShare.h"
#import "RCWorkspace.h"

@implementation RCWorkspaceShare
@synthesize canOpenFiles=__canOpenFiles;
@synthesize canWriteFiles=__canWriteFiles;
@synthesize requiresOwner=__requiresOwner;

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
	__canOpenFiles = [[dict objectForKey:@"canOpenFiles"] boolValue];
	__canWriteFiles = [[dict objectForKey:@"canWriteFiles"] boolValue];
	__requiresOwner = [[dict objectForKey:@"requiresOwner"] boolValue];
}

-(void)setRequiresOwner:(BOOL)requiresOwner
{
	__requiresOwner = requiresOwner;
	[self.workspace updateShare:self permission:@"requiresOwner"];
}

-(void)setCanOpenFiles:(BOOL)canOpenFiles
{
	__canOpenFiles = canOpenFiles;
	[self.workspace updateShare:self permission:@"canOpenFiles"];
}

-(void)setCanWriteFiles:(BOOL)canWriteFiles
{
	__canWriteFiles = canWriteFiles;
	[self.workspace updateShare:self permission:@"canWriteFiles"];
}

@synthesize shareId;
@synthesize userId;
@synthesize userName;
@synthesize workspace;
@end
