//
//  _RCMessage.m
//
//  Created by Mark Lilback
//  Copyright (c) 2012 Agile Monks, LLC. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCMessage.m instead.

#import "_RCMessage.h"

const struct RCMessageAttributes RCMessageAttributes = {
	.body = @"body",
	.dateRead = @"dateRead",
	.dateSent = @"dateSent",
	.messageId = @"messageId",
	.priority = @"priority",
	.rcptmsgId = @"rcptmsgId",
	.sender = @"sender",
	.subject = @"subject",
	.version = @"version",
};

const struct RCMessageRelationships RCMessageRelationships = {
};

const struct RCMessageFetchedProperties RCMessageFetchedProperties = {
};

@implementation RCMessageID
@end

@implementation _RCMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RCMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RCMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RCMessage" inManagedObjectContext:moc_];
}

- (RCMessageID*)objectID {
	return (RCMessageID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"messageIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"messageId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"priorityValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"priority"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"rcptmsgIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"rcptmsgId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"versionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"version"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic body;






@dynamic dateRead;






@dynamic dateSent;






@dynamic messageId;



- (int)messageIdValue {
	NSNumber *result = [self messageId];
	return [result intValue];
}

- (void)setMessageIdValue:(int)value_ {
	[self setMessageId:[NSNumber numberWithInt:value_]];
}

- (int)primitiveMessageIdValue {
	NSNumber *result = [self primitiveMessageId];
	return [result intValue];
}

- (void)setPrimitiveMessageIdValue:(int)value_ {
	[self setPrimitiveMessageId:[NSNumber numberWithInt:value_]];
}





@dynamic priority;



- (short)priorityValue {
	NSNumber *result = [self priority];
	return [result shortValue];
}

- (void)setPriorityValue:(short)value_ {
	[self setPriority:[NSNumber numberWithShort:value_]];
}

- (short)primitivePriorityValue {
	NSNumber *result = [self primitivePriority];
	return [result shortValue];
}

- (void)setPrimitivePriorityValue:(short)value_ {
	[self setPrimitivePriority:[NSNumber numberWithShort:value_]];
}





@dynamic rcptmsgId;



- (int)rcptmsgIdValue {
	NSNumber *result = [self rcptmsgId];
	return [result intValue];
}

- (void)setRcptmsgIdValue:(int)value_ {
	[self setRcptmsgId:[NSNumber numberWithInt:value_]];
}

- (int)primitiveRcptmsgIdValue {
	NSNumber *result = [self primitiveRcptmsgId];
	return [result intValue];
}

- (void)setPrimitiveRcptmsgIdValue:(int)value_ {
	[self setPrimitiveRcptmsgId:[NSNumber numberWithInt:value_]];
}





@dynamic sender;






@dynamic subject;






@dynamic version;



- (int)versionValue {
	NSNumber *result = [self version];
	return [result intValue];
}

- (void)setVersionValue:(int)value_ {
	[self setVersion:[NSNumber numberWithInt:value_]];
}

- (int)primitiveVersionValue {
	NSNumber *result = [self primitiveVersion];
	return [result intValue];
}

- (void)setPrimitiveVersionValue:(int)value_ {
	[self setPrimitiveVersion:[NSNumber numberWithInt:value_]];
}









@end
