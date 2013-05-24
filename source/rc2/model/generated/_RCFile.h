//
//  _RCFile.h
//
//  Created by Mark Lilback
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCFile.h instead.

#import <CoreData/CoreData.h>


extern const struct RCFileAttributes {
	__unsafe_unretained NSString *endDate;
	__unsafe_unretained NSString *fileContents;
	__unsafe_unretained NSString *fileId;
	__unsafe_unretained NSString *isAssignmentFile;
	__unsafe_unretained NSString *lastModified;
	__unsafe_unretained NSString *localAttributes;
	__unsafe_unretained NSString *localEdits;
	__unsafe_unretained NSString *localLastModified;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *readOnly;
	__unsafe_unretained NSString *sizeString;
	__unsafe_unretained NSString *startDate;
	__unsafe_unretained NSString *turnedIn;
	__unsafe_unretained NSString *version;
} RCFileAttributes;

extern const struct RCFileRelationships {
	__unsafe_unretained NSString *savedSessionsRefererencedBy;
} RCFileRelationships;

extern const struct RCFileFetchedProperties {
} RCFileFetchedProperties;

@class RCSavedSession;















@interface RCFileID : NSManagedObjectID {}
@end

@interface _RCFile : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCFileID*)objectID;



@property (nonatomic, strong) NSDate *endDate;


//- (BOOL)validateEndDate:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *fileContents;


//- (BOOL)validateFileContents:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *fileId;


@property int fileIdValue;
- (int)fileIdValue;
- (void)setFileIdValue:(int)value_;

//- (BOOL)validateFileId:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *isAssignmentFile;


@property BOOL isAssignmentFileValue;
- (BOOL)isAssignmentFileValue;
- (void)setIsAssignmentFileValue:(BOOL)value_;

//- (BOOL)validateIsAssignmentFile:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *lastModified;


//- (BOOL)validateLastModified:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSData *localAttributes;


//- (BOOL)validateLocalAttributes:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *localEdits;


//- (BOOL)validateLocalEdits:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *localLastModified;


//- (BOOL)validateLocalLastModified:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *readOnly;


@property BOOL readOnlyValue;
- (BOOL)readOnlyValue;
- (void)setReadOnlyValue:(BOOL)value_;

//- (BOOL)validateReadOnly:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *sizeString;


//- (BOOL)validateSizeString:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *startDate;


//- (BOOL)validateStartDate:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *turnedIn;


@property BOOL turnedInValue;
- (BOOL)turnedInValue;
- (void)setTurnedInValue:(BOOL)value_;

//- (BOOL)validateTurnedIn:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *version;


@property int versionValue;
- (int)versionValue;
- (void)setVersionValue:(int)value_;

//- (BOOL)validateVersion:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* savedSessionsRefererencedBy;

- (NSMutableSet*)savedSessionsRefererencedBySet;




+ (NSArray*)fetchFileById:(NSManagedObjectContext*)moc_ fid:(NSNumber*)fid_ ;
+ (NSArray*)fetchFileById:(NSManagedObjectContext*)moc_ fid:(NSNumber*)fid_ error:(NSError**)error_;



@end

@interface _RCFile (CoreDataGeneratedAccessors)

- (void)addSavedSessionsRefererencedBy:(NSSet*)value_;
- (void)removeSavedSessionsRefererencedBy:(NSSet*)value_;
- (void)addSavedSessionsRefererencedByObject:(RCSavedSession*)value_;
- (void)removeSavedSessionsRefererencedByObject:(RCSavedSession*)value_;

@end

@interface _RCFile (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveEndDate;
- (void)setPrimitiveEndDate:(NSDate*)value;




- (NSString*)primitiveFileContents;
- (void)setPrimitiveFileContents:(NSString*)value;




- (NSNumber*)primitiveFileId;
- (void)setPrimitiveFileId:(NSNumber*)value;

- (int)primitiveFileIdValue;
- (void)setPrimitiveFileIdValue:(int)value_;




- (NSNumber*)primitiveIsAssignmentFile;
- (void)setPrimitiveIsAssignmentFile:(NSNumber*)value;

- (BOOL)primitiveIsAssignmentFileValue;
- (void)setPrimitiveIsAssignmentFileValue:(BOOL)value_;




- (NSDate*)primitiveLastModified;
- (void)setPrimitiveLastModified:(NSDate*)value;




- (NSData*)primitiveLocalAttributes;
- (void)setPrimitiveLocalAttributes:(NSData*)value;




- (NSString*)primitiveLocalEdits;
- (void)setPrimitiveLocalEdits:(NSString*)value;




- (NSDate*)primitiveLocalLastModified;
- (void)setPrimitiveLocalLastModified:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveReadOnly;
- (void)setPrimitiveReadOnly:(NSNumber*)value;

- (BOOL)primitiveReadOnlyValue;
- (void)setPrimitiveReadOnlyValue:(BOOL)value_;




- (NSString*)primitiveSizeString;
- (void)setPrimitiveSizeString:(NSString*)value;




- (NSDate*)primitiveStartDate;
- (void)setPrimitiveStartDate:(NSDate*)value;




- (NSNumber*)primitiveTurnedIn;
- (void)setPrimitiveTurnedIn:(NSNumber*)value;

- (BOOL)primitiveTurnedInValue;
- (void)setPrimitiveTurnedInValue:(BOOL)value_;




- (NSNumber*)primitiveVersion;
- (void)setPrimitiveVersion:(NSNumber*)value;

- (int)primitiveVersionValue;
- (void)setPrimitiveVersionValue:(int)value_;





- (NSMutableSet*)primitiveSavedSessionsRefererencedBy;
- (void)setPrimitiveSavedSessionsRefererencedBy:(NSMutableSet*)value;


@end
