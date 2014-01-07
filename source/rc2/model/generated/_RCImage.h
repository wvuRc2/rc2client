//
//  _RCImage.h
//
//  Created by Mark Lilback
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCImage.h instead.

#import <CoreData/CoreData.h>


extern const struct RCImageAttributes {
	__unsafe_unretained NSString *imageId;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *timestamp;
} RCImageAttributes;

extern const struct RCImageRelationships {
} RCImageRelationships;

extern const struct RCImageFetchedProperties {
} RCImageFetchedProperties;





@interface RCImageID : NSManagedObjectID {}
@end

@interface _RCImage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCImageID*)objectID;



@property (nonatomic, strong) NSNumber *imageId;


@property int imageIdValue;
- (int)imageIdValue;
- (void)setImageIdValue:(int)value_;

//- (BOOL)validateImageId:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *timestamp;


//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;





@end

@interface _RCImage (CoreDataGeneratedAccessors)

@end

@interface _RCImage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveImageId;
- (void)setPrimitiveImageId:(NSNumber*)value;

- (int)primitiveImageIdValue;
- (void)setPrimitiveImageIdValue:(int)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSDate*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(NSDate*)value;




@end
