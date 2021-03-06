//
//  RCVariable.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/5/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	ePrimType_Unknown=0,
	ePrimType_Boolean,
	ePrimType_Integer,
	ePrimType_Double,
	ePrimType_String,
	ePrimType_Complex,
	ePrimType_Raw,
	ePrimType_Null,
	ePrimType_NA
} RCPrimitiveType;

typedef enum {
	eVarType_Unknown=0,
	eVarType_Primitive,
	eVarType_Vector,
	eVarType_Matrix,
	eVarType_Array,
	eVarType_List,
	eVarType_Factor,
	eVarType_DataFrame,
	eVarType_Environment,
	eVarType_Function,
	eVarType_S3Object,
	eVarType_S4Object
} RCVariableType;

@class RCList;

@interface RCVariable : NSObject {
	@protected
	RCVariableType _type; //needed so subclasses can write to the value
}
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *fullyQualifiedName; //foo[0][2][3] etc.
@property (nonatomic, copy, readonly) NSString *className; //from R
@property (nonatomic, readonly) NSString *description; //want different value for debugger
@property (nonatomic, readonly) NSString *summary;

@property (readonly) RCVariableType type;
@property (readonly) RCPrimitiveType primitiveType; //=Unknown if type != eVarType_Vector
@property (nonatomic, readonly) BOOL isPrimitive;
@property (nonatomic, readonly) BOOL isFactor;
@property (nonatomic, readonly) BOOL isDate;
@property (nonatomic, readonly) BOOL isDateTime;
@property (nonatomic) BOOL justUpdated; //for client to manage, not used internally

@property (nonatomic, weak) RCList *parentList;
	
@property (nonatomic, readonly) NSInteger length; //how many items on server
@property (nonatomic, readonly) NSInteger count; //how many are accessible via valueAtIndex:

@property (nonatomic, readonly) BOOL treatAsContainerType; //for display to the user under the "data" heading

-(RCVariable*)valueAtIndex:(NSUInteger)idx;

+(id)variableWithDictionary:(NSDictionary*)dict;

//convience methods for specific variable types
@property (nonatomic, readonly) NSString *functionBody;

//for subclasses to override
-(id)initWithDictionary:(NSDictionary*)dict;
-(void)decodeSupportedObjects:(NSDictionary*)dict;
@property BOOL summaryIsDescription;
//for subclass use only
@property (nonatomic, copy) NSArray *values;
@end

@protocol RCSpreadsheetData <NSObject>

@property (nonatomic, readonly) NSInteger rowCount;
@property (nonatomic, readonly) NSInteger colCount;
@property (nonatomic, copy, readonly) NSArray *columnNames;
@property (nonatomic, copy, readonly) NSArray *rowNames;

-(NSString*)valueAtRow:(int)row column:(int)col;

@end
