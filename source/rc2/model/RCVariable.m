//
//  RCVariable.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/5/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCVariable.h"
#import <xlocale.h>

@interface RCVariable ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *className; //from R
@property (nonatomic, copy) NSArray *values;
@property (readwrite) RCVariableType type;
@property (readwrite) RCPrimitiveType primitiveType; //=Unknown if type != eVarType_Vector
@property BOOL summaryIsDescription;
@end

@implementation RCVariable

+(NSDateFormatter*)dateFormatter
{
	static dispatch_once_t onceToken;
	static NSDateFormatter *dateFormatter;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		dateFormatter.dateFormat = @"%yyyy-%MM-%DD";
	});
	return dateFormatter;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.name = [dict objectForKey:@"name"];
		self.className = [dict objectForKey:@"class"];
		BOOL primitive = [[dict objectForKey:@"primitive"] boolValue];
		if (primitive) {
			self.type = eVarType_Primitive;
			self.primitiveType = [self primitiveTypeForString:[dict objectForKey:@"type"]];
			self.values = [dict objectForKey:@"value"];
			if (self.primitiveType == ePrimType_Double) {
				//special handling for inifinty and NaN
				NSUInteger idx = [self.values indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
					if ([obj isKindOfClass:[NSString class]]) {
						*stop = YES;
							return YES;
					}
					return NO;
				}];
				if (idx != NSNotFound) {
					//has special values
					NSMutableArray *ma = self.values.mutableCopy;
					for (int i=0; i < ma.count; i++) {
					    id obj = [ma objectAtIndex:i];
						    if ([obj isKindOfClass:[NSString class]]) {
					        if ([obj isEqualToString:@"Inf"])
					            [ma replaceObjectAtIndex:idx withObject:(__bridge NSNumber*)kCFNumberPositiveInfinity];
					        else if ([obj isEqualToString:@"-Inf"])
								            [ma replaceObjectAtIndex:idx withObject:(__bridge NSNumber*)kCFNumberNegativeInfinity];
					        else
								            [ma replaceObjectAtIndex:idx withObject:(__bridge NSNumber*)kCFNumberNaN];
							    }
					}
					self.values = ma;
					NSLog(@"transformed numbers: %@", self.values);
				}
			}
		} else if ([dict objectForKey:@"levels"]) {
			self.type = eVarType_Factor;
			_levels = [dict objectForKey:@"levels"];
		} else {
			[self decodeSupportedObjects:dict];
		}
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
	} else if (self.isDate) {
		return  [self.values objectAtIndex:1];
	} else if (self.isDateTime) {
		return [(NSDate*)[self.values objectAtIndex:0] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil];
	}
	return [NSString stringWithFormat:@"%@[%d]", self.className, (int)self.values.count];
}

#pragma mark - private

-(void)decodeSupportedObjects:(NSDictionary*)dict
{
	NSString *cname = [dict objectForKey:@"class"];
	if ([cname isEqualToString:@"Date"]) {
		//store the string version as second value
		struct tm tmtime;
		bzero(&tmtime, sizeof(tmtime));
		strptime_l([[dict objectForKey:@"value"] UTF8String], "%F", &tmtime, NULL);
		NSDate *dval = [NSDate dateWithTimeIntervalSince1970:mktime(&tmtime)];
		if (dval) {
			self.values = @[dval, [dict objectForKey:@"value"]];
			self.summaryIsDescription = YES;
		} else {
			Rc2LogWarn(@"failed to parse date object:%@", dict);
		}
	} else if ([cname isEqualToString:@"POSIXct"] || [cname isEqualToString:@"POSIXlt"]) {
		self.values = @[[NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"value"] doubleValue]]];
		self.summaryIsDescription = YES;
	}
}

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

-(BOOL)isDate
{
	return [self.className isEqualToString:@"Date"];
}

-(BOOL)isDateTime
{
	return [self.className isEqualToString:@"POSIXct"] || [self.className isEqualToString:@"POSIXlt"];
}

-(NSString*)summary
{
	switch (self.type) {
		case eVarType_Factor:
			return [self.levels componentsJoinedByString:@", "];
		case eVarType_Primitive:
			return [self.values componentsJoinedByString:@","];
		default:
			if (self.summaryIsDescription)
				return self.description;
			break;
	}
	return nil;
}
@end
