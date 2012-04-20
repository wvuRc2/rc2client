//
//  RCWorkspaceFolder.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCWorkspaceFolder.h"

@interface RCWorkspaceFolder() {
	NSMutableArray *_children;
}
@end

@implementation RCWorkspaceFolder

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super initWithDictionary:dict])) {
		_children = [[NSMutableArray alloc] init];
	}
	return self;
}


-(BOOL)isFolder { return YES; }

-(BOOL)canDelete
{
	if ([self.name isEqualToString:@"shared"])
		return NO;
	return YES;
}

-(NSArray*)children
{
	return [_children copy];
}

-(void)addChild:(RCWorkspaceItem *)aChild
{
	if (![_children containsObject:aChild]) {
		[_children addObject:aChild];
		[_children sortUsingSelector:@selector(compareWithItem:)];
	}
}

-(void)removeChild:(RCWorkspaceItem*)aChild
{
	[_children removeObject:aChild];
}

-(RCWorkspaceItem*)childWithId:(NSNumber*)theId
{
	RCWorkspaceItem *item=nil;
	for (RCWorkspaceItem *aChild in _children) {
		if ([aChild.wspaceId isEqualToNumber:theId]) {
			item = aChild;
			break;
		} else if (aChild.isFolder) {
			item = [(RCWorkspaceFolder*)aChild childWithId:theId];
			if (item)
				break;
		}
	}
	return item;
}

@end
