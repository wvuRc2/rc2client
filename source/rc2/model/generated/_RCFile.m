//
//  _RCFile.m
//
//  Created by Mark Lilback
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCFile.m instead.

#import "_RCFile.h"

const struct RCFileAttributes RCFileAttributes = {
	.fileContents = @"fileContents",
	.fileId = @"fileId",
	.isAssignmentFile = @"isAssignmentFile",
	.lastModified = @"lastModified",
	.localAttributes = @"localAttributes",
	.localEdits = @"localEdits",
	.localLastModified = @"localLastModified",
	.name = @"name",
	.readOnly = @"readOnly",
	.sizeString = @"sizeString",
	.version = @"version",
};

const struct RCFileRelationships RCFileRelationships = {
	.savedSessionsRefererencedBy = @"savedSessionsRefererencedBy",
};

const struct RCFileFetchedProperties RCFileFetchedProperties = {
};

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
	if ([key isEqualToString:@"isAssignmentFileValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isAssignmentFile"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"readOnlyValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"readOnly"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"versionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"version"];
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





@dynamic isAssignmentFile;



- (BOOL)isAssignmentFileValue {
	NSNumber *result = [self isAssignmentFile];
	return [result boolValue];
}

- (void)setIsAssignmentFileValue:(BOOL)value_ {
	[self setIsAssignmentFile:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsAssignmentFileValue {
	NSNumber *result = [self primitiveIsAssignmentFile];
	return [result boolValue];
}

- (void)setPrimitiveIsAssignmentFileValue:(BOOL)value_ {
	[self setPrimitiveIsAssignmentFile:[NSNumber numberWithBool:value_]];
}





@dynamic lastModified;






@dynamic localAttributes;






@dynamic localEdits;






@dynamic localLastModified;






@dynamic name;






@dynamic readOnly;



- (BOOL)readOnlyValue {
	NSNumber *result = [self readOnly];
	return [result boolValue];
}

- (void)setReadOnlyValue:(BOOL)value_ {
	[self setReadOnly:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveReadOnlyValue {
	NSNumber *result = [self primitiveReadOnly];
	return [result boolValue];
}

- (void)setPrimitiveReadOnlyValue:(BOOL)value_ {
	[self setPrimitiveReadOnly:[NSNumber numberWithBool:value_]];
}





@dynamic sizeString;






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
