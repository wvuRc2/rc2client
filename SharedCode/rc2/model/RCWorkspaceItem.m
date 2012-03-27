//
//  RC2WorkspaceItem.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCWorkspaceItem.h"
#import "RCWorkspace.h"
#import "RCWorkspaceFolder.h"

@implementation RCWorkspaceItem

+(id)workspaceItemWithDictionary:(NSDictionary*)dict
{
	Class cl = [RCWorkspace class];
	if ([[dict objectForKey:@"isDir"] boolValue])
		cl = [RCWorkspaceFolder class];
	RCWorkspaceItem *item = [[cl alloc] initWithDictionary:dict];
	return item;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.name = [dict objectForKey:@"name"];
		self.wspaceId = [dict objectForKey:@"id"];
		id pid = [dict objectForKey:@"parid"];
		if (pid == [NSNull null] || [pid intValue] == 0)
			pid = nil;
		self.parentId = pid;
	}
	return self;
}


-(BOOL)isFolder { return NO; }

-(NSComparisonResult)compareWithItem:(RCWorkspaceItem*)anItem
{
	//shared folder is always first
	if (anItem.isFolder && anItem.wspaceId.integerValue == -1)
		return NSOrderedDescending;
	//folders come before workspaces
	if (self.isFolder != anItem.isFolder)
		return self.isFolder ? NSOrderedAscending : NSOrderedDescending;
	//alphabetical as per OS
	return [self.name localizedStandardCompare: anItem.name];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"<%@ id=%@, name=\"%@\">", NSStringFromClass([self class]), self.wspaceId, self.name];
}

@synthesize wspaceId;
@synthesize parentId;
@synthesize name;
@synthesize parentItem=_parentItem;
@end
