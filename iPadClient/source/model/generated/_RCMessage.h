// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCMessage.h instead.

#import <CoreData/CoreData.h>













@interface RCMessageID : NSManagedObjectID {}
@end

@interface _RCMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCMessageID*)objectID;




@property (nonatomic, retain) NSString *body;


//- (BOOL)validateBody:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *dateRead;


//- (BOOL)validateDateRead:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *dateSent;


//- (BOOL)validateDateSent:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *messageId;


@property int messageIdValue;
- (int)messageIdValue;
- (void)setMessageIdValue:(int)value_;

//- (BOOL)validateMessageId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *priority;


@property short priorityValue;
- (short)priorityValue;
- (void)setPriorityValue:(short)value_;

//- (BOOL)validatePriority:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *rcptmsgId;


@property int rcptmsgIdValue;
- (int)rcptmsgIdValue;
- (void)setRcptmsgIdValue:(int)value_;

//- (BOOL)validateRcptmsgId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *sender;


//- (BOOL)validateSender:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *subject;


//- (BOOL)validateSubject:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *version;


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
