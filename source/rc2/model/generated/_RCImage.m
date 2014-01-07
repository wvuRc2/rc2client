//
//  _RCImage.m
//
//  Created by Mark Lilback
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCImage.m instead.

#import "_RCImage.h"

const struct RCImageAttributes RCImageAttributes = {
	.imageId = @"imageId",
	.name = @"name",
	.timestamp = @"timestamp",
};

const struct RCImageRelationships RCImageRelationships = {
};

const struct RCImageFetchedProperties RCImageFetchedProperties = {
};

@implementation RCImageID
@end

@implementation _RCImage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RCImage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RCImage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RCImage" inManagedObjectContext:moc_];
}

- (RCImageID*)objectID {
	return (RCImageID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"imageIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"imageId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic imageId;



- (int)imageIdValue {
	NSNumber *result = [self imageId];
	return [result intValue];
}

- (void)setImageIdValue:(int)value_ {
	[self setImageId:[NSNumber numberWithInt:value_]];
}

- (int)primitiveImageIdValue {
	NSNumber *result = [self primitiveImageId];
	return [result intValue];
}

- (void)setPrimitiveImageIdValue:(int)value_ {
	[self setPrimitiveImageId:[NSNumber numberWithInt:value_]];
}





@dynamic name;






@dynamic timestamp;










@end
