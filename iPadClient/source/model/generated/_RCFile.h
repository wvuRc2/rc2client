// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCFile.h instead.

#import <CoreData/CoreData.h>


@class RCSavedSession;










@interface RCFileID : NSManagedObjectID {}
@end

@interface _RCFile : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCFileID*)objectID;




@property (nonatomic, retain) NSString *fileContents;


//- (BOOL)validateFileContents:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *fileId;


@property int fileIdValue;
- (int)fileIdValue;
- (void)setFileIdValue:(int)value_;

//- (BOOL)validateFileId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *lastModified;


//- (BOOL)validateLastModified:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *localEdits;


//- (BOOL)validateLocalEdits:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *localLastModified;


//- (BOOL)validateLocalLastModified:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *sizeString;


//- (BOOL)validateSizeString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *wspaceId;


@property int wspaceIdValue;
- (int)wspaceIdValue;
- (void)setWspaceIdValue:(int)value_;

//- (BOOL)validateWspaceId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet* savedSessionsRefererencedBy;

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


- (NSString*)primitiveFileContents;
- (void)setPrimitiveFileContents:(NSString*)value;




- (NSNumber*)primitiveFileId;
- (void)setPrimitiveFileId:(NSNumber*)value;

- (int)primitiveFileIdValue;
- (void)setPrimitiveFileIdValue:(int)value_;




- (NSDate*)primitiveLastModified;
- (void)setPrimitiveLastModified:(NSDate*)value;




- (NSString*)primitiveLocalEdits;
- (void)setPrimitiveLocalEdits:(NSString*)value;




- (NSDate*)primitiveLocalLastModified;
- (void)setPrimitiveLocalLastModified:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveSizeString;
- (void)setPrimitiveSizeString:(NSString*)value;




- (NSNumber*)primitiveWspaceId;
- (void)setPrimitiveWspaceId:(NSNumber*)value;

- (int)primitiveWspaceIdValue;
- (void)setPrimitiveWspaceIdValue:(int)value_;





- (NSMutableSet*)primitiveSavedSessionsRefererencedBy;
- (void)setPrimitiveSavedSessionsRefererencedBy:(NSMutableSet*)value;


@end
