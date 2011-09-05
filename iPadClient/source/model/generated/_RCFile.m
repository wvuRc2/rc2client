// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCFile.m instead.

#import "_RCFile.h"

@implementation RCFileID
@end

@implementation _RCFile

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RCFile" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RCFile";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RCFile" inManagedObjectContext:moc_];
}

- (RCFileID*)objectID {
	return (RCFileID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"fileIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fileId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"wspaceIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"wspaceId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic fileContents;






@dynamic fileId;



- (int)fileIdValue {
	NSNumber *result = [self fileId];
	return [result intValue];
}

- (void)setFileIdValue:(int)value_ {
	[self setFileId:[NSNumber numberWithInt:value_]];
}

- (int)primitiveFileIdValue {
	NSNumber *result = [self primitiveFileId];
	return [result intValue];
}

- (void)setPrimitiveFileIdValue:(int)value_ {
	[self setPrimitiveFileId:[NSNumber numberWithInt:value_]];
}





@dynamic lastModified;






@dynamic localEdits;






@dynamic localLastModified;






@dynamic name;






@dynamic sizeString;






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





@dynamic savedSessionsRefererencedBy;

	
- (NSMutableSet*)savedSessionsRefererencedBySet {
	[self willAccessValueForKey:@"savedSessionsRefererencedBy"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"savedSessionsRefererencedBy"];
	[self didAccessValueForKey:@"savedSessionsRefererencedBy"];
	return result;
}
	






+ (NSArray*)fetchFileById:(NSManagedObjectContext*)moc_ fid:(NSNumber*)fid_ {
	NSError *error = nil;
	NSArray *result = [self fetchFileById:moc_ fid:fid_ error:&error];
	if (error) {
#if TARGET_OS_IPHONE
		NSLog(@"error: %@", error);
#else
		[NSApp presentError:error];
#endif
	}
	return result;
}
+ (NSArray*)fetchFileById:(NSManagedObjectContext*)moc_ fid:(NSNumber*)fid_ error:(NSError**)error_ {
	NSParameterAssert(moc_);
	NSError *error = nil;
	
	NSManagedObjectModel *model = [[moc_ persistentStoreCoordinator] managedObjectModel];
	
	NSDictionary *substitutionVariables = [NSDictionary dictionaryWithObjectsAndKeys:
														
														fid_, @"fid",
														
														nil];
										
	NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"fileById"
													 substitutionVariables:substitutionVariables];
	NSAssert(fetchRequest, @"Can't find fetch request named \"fileById\".");
	
	NSArray *result = [moc_ executeFetchRequest:fetchRequest error:&error];
	if (error_) *error_ = error;
	return result;
}


@end
