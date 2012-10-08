//
//  RCVariable.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/5/12.
//  Copyright 2012 Agile Monks. All rights reserved.
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
	ePrimType_NA,
	ePrimType_Infinity
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
	eVarType_S3Object,
	eVarType_S4Object
} RCVariableType;

@interface RCVariable : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *className; //from R
@property (nonatomic, readonly) NSString *description; //want different value for debugger
@property (nonatomic, readonly) NSString *summary;

@property (nonatomic, readonly) NSArray *levels; //for a factor only. nil otherwise.

@property (readonly) RCVariableType type;
@property (readonly) RCPrimitiveType primitiveType; //=Unknown if type != eVarType_Vector
@property (nonatomic, readonly) BOOL isPrimitive;
@property (nonatomic, readonly) BOOL isFactor;

@property (nonatomic, readonly) NSInteger count;

-(RCVariable*)valueAtIndex:(NSUInteger)idx;


-(id)initWithDictionary:(NSDictionary*)dict;
@end
