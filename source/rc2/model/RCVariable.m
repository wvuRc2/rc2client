//
//  RCVariable.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/5/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCVariable.h"

@interface RCVariable ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *className; //from R
@property (nonatomic, copy) NSArray *values;
@property (readwrite) RCVariableType type;
@property (readwrite) RCPrimitiveType primitiveType; //=Unknown if type != eVarType_Vector
@end

@implementation RCVariable

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.name = [dict objectForKey:@"name"];
		BOOL primitive = [[dict objectForKey:@"primitive"] boolValue];
		if (primitive) {
			self.type = eVarType_Primitive;
			self.primitiveType = [self primitiveTypeForString:[dict objectForKey:@"type"]];
			self.values = [dict objectForKey:@"value"];
		}
		if ([dict objectForKey:@"levels"]) {
			self.type = eVarType_Factor;
			_levels = [dict objectForKey:@"levels"];
		}
		self.className = [dict objectForKey:@"class"];
	}
	return self;
}

#pragma mark - public

-(RCVariable*)valueAtIndex:(NSUInteger)idx
{
	return [self.values objectAtIndex:idx];
}

-(NSString*)description
{
	if (self.isPrimitive) {
		if (self.values.count == 1)
			return [[self.values objectAtIndex:0] description];
	} else if (self.isFactor) {
		return [NSString stringWithFormat:@"%@[%d]", self.className, (int)self.levels.count];
	}
	return [NSString stringWithFormat:@"%@[%d]", self.className, (int)self.values.count];
}

#pragma mark - private

-(RCPrimitiveType)primitiveTypeForString:(NSString*)str
{
	if (str.length < 1)
		return ePrimType_Unknown;
	switch ([str characterAtIndex:0]) {
		case 'd':
			return ePrimType_Double;
		case 'i':
			return ePrimType_Integer;
		case 's':
			return ePrimType_String;
		case 'b':
			return ePrimType_Boolean;
		default:
			return ePrimType_Unknown;
	}
}

#pragma mark - accessors

-(NSInteger)count
{
	return self.values.count;
}

-(BOOL)isPrimitive
{
	return self.type == eVarType_Primitive;
}

-(BOOL)isFactor
{
	return self.type == eVarType_Factor;
}

-(NSString*)summary
{
	switch (self.type) {
		case eVarType_Factor:
			return [self.levels componentsJoinedByString:@", "];
		case eVarType_Primitive:
			return [self.values componentsJoinedByString:@","];
		default:
			break;
	}
	return nil;
}
@end
