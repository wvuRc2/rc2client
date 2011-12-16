//
//  _RCWorkspaceCache.m
//
//  Created by Mark Lilback
//  Copyright (c) 2011 . All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCWorkspaceCache.m instead.

#import "_RCWorkspaceCache.h"

const struct RCWorkspaceCacheAttributes RCWorkspaceCacheAttributes = {
	.localAttributes = @"localAttributes",
	.wspaceId = @"wspaceId",
};

const struct RCWorkspaceCacheRelationships RCWorkspaceCacheRelationships = {
};

const struct RCWorkspaceCacheFetchedProperties RCWorkspaceCacheFetchedProperties = {
};

@implementation RCWorkspaceCacheID
@end

@implementation _RCWorkspaceCache

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WorkspaceCache" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WorkspaceCache";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WorkspaceCache" inManagedObjectContext:moc_];
}

- (RCWorkspaceCacheID*)objectID {
	return (RCWorkspaceCacheID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"wspaceIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"wspaceId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic localAttributes;






@dynamic wspaceId;



- (int)wspaceIdValue {
	NSNumber *result = [self wspaceId];
	return [result intValue];
}

- (void)setWspaceIdValue:(int)value_ {
	[self setWspaceId:[NSNumber numberWithInt:value_]];
}

- (int)primitiveWspaceIdValue {
	NSNumber *result = [self primitiveWspaceId];
	return [result intValue];
}

- (void)setPrimitiveWspaceIdValue:(int)value_ {
	[self setPrimitiveWspaceId:[NSNumber numberWithInt:value_]];
}









@end
