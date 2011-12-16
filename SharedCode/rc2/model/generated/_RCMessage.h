//
//  _RCMessage.h
//
//  Created by Mark Lilback
//  Copyright (c) 2011 . All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct RCMessageAttributes {
	__unsafe_unretained NSString *body;
	__unsafe_unretained NSString *dateRead;
	__unsafe_unretained NSString *dateSent;
	__unsafe_unretained NSString *messageId;
	__unsafe_unretained NSString *priority;
	__unsafe_unretained NSString *rcptmsgId;
	__unsafe_unretained NSString *sender;
	__unsafe_unretained NSString *subject;
	__unsafe_unretained NSString *version;
} RCMessageAttributes;

extern const struct RCMessageRelationships {
} RCMessageRelationships;

extern const struct RCMessageFetchedProperties {
} RCMessageFetchedProperties;











@interface RCMessageID : NSManagedObjectID {}
@end

@interface _RCMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCMessageID*)objectID;



@property (nonatomic, strong) NSString *body;


//- (BOOL)validateBody:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *dateRead;


//- (BOOL)validateDateRead:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSDate *dateSent;


//- (BOOL)validateDateSent:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *messageId;


@property int messageIdValue;
- (int)messageIdValue;
- (void)setMessageIdValue:(int)value_;

//- (BOOL)validateMessageId:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *priority;


@property short priorityValue;
- (short)priorityValue;
- (void)setPriorityValue:(short)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *rcptmsgId;


@property int rcptmsgIdValue;
- (int)rcptmsgIdValue;
- (void)setRcptmsgIdValue:(int)value_;

//- (BOOL)validateRcptmsgId:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *sender;


//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *subject;


//- (BOOL)validateSubject:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *version;


@property int versionValue;
- (int)versionValue;
- (void)setVersionValue:(int)value_;

//- (BOOL)validateVersion:(id*)value_ error:(NSError**)error_;





@end

@interface _RCMessage (CoreDataGeneratedAccessors)

@end

@interface _RCMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveBody;
- (void)setPrimitiveBody:(NSString*)value;




- (NSDate*)primitiveDateRead;
- (void)setPrimitiveDateRead:(NSDate*)value;




- (NSDate*)primitiveDateSent;
- (void)setPrimitiveDateSent:(NSDate*)value;




- (NSNumber*)primitiveMessageId;
- (void)setPrimitiveMessageId:(NSNumber*)value;

- (int)primitiveMessageIdValue;
- (void)setPrimitiveMessageIdValue:(int)value_;




- (NSNumber*)primitivePriority;
- (void)setPrimitivePriority:(NSNumber*)value;

- (short)primitivePriorityValue;
- (void)setPrimitivePriorityValue:(short)value_;




- (NSNumber*)primitiveRcptmsgId;
- (void)setPrimitiveRcptmsgId:(NSNumber*)value;

- (int)primitiveRcptmsgIdValue;
- (void)setPrimitiveRcptmsgIdValue:(int)value_;




- (NSString*)primitiveSender;
- (void)setPrimitiveSender:(NSString*)value;




- (NSString*)primitiveSubject;
- (void)setPrimitiveSubject:(NSString*)value;




- (NSNumber*)primitiveVersion;
- (void)setPrimitiveVersion:(NSNumber*)value;

- (int)primitiveVersionValue;
- (void)setPrimitiveVersionValue:(int)value_;




@end
