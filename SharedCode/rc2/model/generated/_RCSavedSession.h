// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RCSavedSession.h instead.

#import <CoreData/CoreData.h>


@class RCFile;






@interface RCSavedSessionID : NSManagedObjectID {}
@end

@interface _RCSavedSession : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RCSavedSessionID*)objectID;




@property (nonatomic, strong) NSString *consoleHtml;


//- (BOOL)validateConsoleHtml:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *inputText;


//- (BOOL)validateInputText:(id*)value_ error:(NSError**)error_;




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


- (NSString*)primitiveConsoleHtml;
- (void)setPrimitiveConsoleHtml:(NSString*)value;




- (NSString*)primitiveInputText;
- (void)setPrimitiveInputText:(NSString*)value;




- (NSString*)primitiveLogin;
- (void)setPrimitiveLogin:(NSString*)value;




- (NSNumber*)primitiveWspaceId;
- (void)setPrimitiveWspaceId:(NSNumber*)value;

- (int)primitiveWspaceIdValue;
- (void)setPrimitiveWspaceIdValue:(int)value_;





- (RCFile*)primitiveCurrentFile;
- (void)setPrimitiveCurrentFile:(RCFile*)value;


@end
