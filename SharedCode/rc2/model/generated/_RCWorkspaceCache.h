// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCWorkspaceCache.h instead.

#import <CoreData/CoreData.h>






@interface RCWorkspaceCacheID : NSManagedObjectID {}
@end

@interface _RCWorkspaceCache : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCWorkspaceCacheID*)objectID;




@property (nonatomic, strong) NSData *localAttributes;


//- (BOOL)validateLocalAttributes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *wspaceId;


@property int wspaceIdValue;
- (int)wspaceIdValue;
- (void)setWspaceIdValue:(int)value_;

//- (BOOL)validateWspaceId:(id*)value_ error:(NSError**)error_;





@end

@interface _RCWorkspaceCache (CoreDataGeneratedAccessors)

@end

@interface _RCWorkspaceCache (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveLocalAttributes;
- (void)setPrimitiveLocalAttributes:(NSData*)value;




- (NSNumber*)primitiveWspaceId;
- (void)setPrimitiveWspaceId:(NSNumber*)value;

- (int)primitiveWspaceIdValue;
- (void)setPrimitiveWspaceIdValue:(int)value_;




@end
