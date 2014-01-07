//
//  _RCSavedSession.m
//
//  Created by Mark Lilback
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCSavedSession.m instead.

#import "_RCSavedSession.h"

const struct RCSavedSessionAttributes RCSavedSessionAttributes = {
	.cmdHistoryData = @"cmdHistoryData",
	.consoleRtf = @"consoleRtf",
	.inputText = @"inputText",
	.localAttributes = @"localAttributes",
	.login = @"login",
	.wspaceId = @"wspaceId",
};

const struct RCSavedSessionRelationships RCSavedSessionRelationships = {
	.currentFile = @"currentFile",
};

const struct RCSavedSessionFetchedProperties RCSavedSessionFetchedProperties = {
};

@implementation RCSavedSessionID
@end

@implementation _RCSavedSession

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RCSavedSession" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RCSavedSession";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RCSavedSession" inManagedObjectContext:moc_];
}

- (RCSavedSessionID*)objectID {
	return (RCSavedSessionID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"wspaceIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"wspaceId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic cmdHistoryData;






@dynamic consoleRtf;






@dynamic inputText;






@dynamic localAttributes;






@dynamic login;






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





@dynamic currentFile;

	






+ (NSArray*)fetchSavedSession:(NSManagedObjectContext*)moc_ wspaceId:(NSNumber*)wspaceId_ {
	NSError *error = nil;
	NSArray *result = [self fetchSavedSession:moc_ wspaceId:wspaceId_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchSavedSession:(NSManagedObjectContext*)moc_ wspaceId:(NSNumber*)wspaceId_ error:(NSError**)error_ {
	NSParameterAssert(moc_);
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	
	NSDictionary *substitutionVariables = [NSDictionary dictionaryWithObjectsAndKeys:
														
														wspaceId_, @"wspaceId",
														
														nil];
										
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"savedSession"
													 substitutionVariables:substitutionVariables];
	NSAssert(fetchRequest, @"Can't find fetch request named \"savedSession\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
