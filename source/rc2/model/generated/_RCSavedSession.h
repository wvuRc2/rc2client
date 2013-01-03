//
//  _RCSavedSession.h
//
//  Created by Mark Lilback
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCSavedSession.h instead.

#import <CoreData/CoreData.h>


extern const struct RCSavedSessionAttributes {
	__unsafe_unretained NSString *cmdHistoryData;
	__unsafe_unretained NSString *consoleHtml;
	__unsafe_unretained NSString *inputText;
	__unsafe_unretained NSString *localAttributes;
	__unsafe_unretained NSString *login;
	__unsafe_unretained NSString *wspaceId;
} RCSavedSessionAttributes;

extern const struct RCSavedSessionRelationships {
	__unsafe_unretained NSString *currentFile;
} RCSavedSessionRelationships;

extern const struct RCSavedSessionFetchedProperties {
} RCSavedSessionFetchedProperties;

@class RCFile;







@interface RCSavedSessionID : NSManagedObjectID {}
@end

@interface _RCSavedSession : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCSavedSessionID*)objectID;



@property (nonatomic, strong) NSData *cmdHistoryData;


//- (BOOL)validateCmdHistoryData:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *consoleHtml;


//- (BOOL)validateConsoleHtml:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *inputText;


//- (BOOL)validateInputText:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSData *localAttributes;


//- (BOOL)validateLocalAttributes:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSString *login;


//- (BOOL)validateLogin:(id*)value_ error:(NSError**)error_;



@property (nonatomic, strong) NSNumber *wspaceId;


@property int wspaceIdValue;
- (int)wspaceIdValue;
- (void)setWspaceIdValue:(int)value_;

//- (BOOL)validateWspaceId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) RCFile* currentFile;

//- (BOOL)validateCurrentFile:(id*)value_ error:(NSError**)error_;




+ (NSArray*)fetchSavedSession:(NSManagedObjectContext*)moc_ wspaceId:(NSNumber*)wspaceId_ ;
+ (NSArray*)fetchSavedSession:(NSManagedObjectContext*)moc_ wspaceId:(NSNumber*)wspaceId_ error:(NSError**)error_;



@end

@interface _RCSavedSession (CoreDataGeneratedAccessors)

@end

@interface _RCSavedSession (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveCmdHistoryData;
- (void)setPrimitiveCmdHistoryData:(NSData*)value;




- (NSString*)primitiveConsoleHtml;
- (void)setPrimitiveConsoleHtml:(NSString*)value;




- (NSString*)primitiveInputText;
- (void)setPrimitiveInputText:(NSString*)value;




- (NSData*)primitiveLocalAttributes;
- (void)setPrimitiveLocalAttributes:(NSData*)value;




- (NSString*)primitiveLogin;
- (void)setPrimitiveLogin:(NSString*)value;




- (NSNumber*)primitiveWspaceId;
- (void)setPrimitiveWspaceId:(NSNumber*)value;

- (int)primitiveWspaceIdValue;
- (void)setPrimitiveWspaceIdValue:(int)value_;





- (RCFile*)primitiveCurrentFile;
- (void)setPrimitiveCurrentFile:(RCFile*)value;


@end
