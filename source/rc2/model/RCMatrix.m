//
//  RCMatrix.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCMatrix.h"

@interface RCMatrix ()
@property (nonatomic, readwrite) NSInteger rowCount;
@property (nonatomic, readwrite) NSInteger colCount;
@property (nonatomic, strong) NSNumberFormatter *decFormatter;
@property (nonatomic, copy, readwrite) NSArray *columnNames;
@property (nonatomic, copy, readwrite) NSArray *rowNames;
@end

@implementation RCMatrix

-(id)initWithDictionary:(NSDictionary *)dict
{
	if ((self = [super initWithDictionary:dict])) {
		self.rowCount = [[dict objectForKey:@"nrow"] longValue];
		self.colCount = [[dict objectForKey:@"ncol"] longValue];
		if (self.primitiveType == ePrimType_Double) {
			self.decFormatter = [[NSNumberFormatter alloc] init];
			self.decFormatter.positiveFormat = @"###0.####";
			self.decFormatter.maximumFractionDigits = 4;
		}
		NSArray *dimnames = [dict objectForKey:@"dimnames"];
		if (dimnames.count > 0) {
			self.rowNames = [dimnames objectAtIndex:0];
			if (dimnames.count > 1)
				self.columnNames = [dimnames objectAtIndex:1];
		}
		if (nil == self.columnNames) {
			NSMutableArray *ma = [NSMutableArray arrayWithCapacity:self.colCount];
			for (int i=0; i < _colCount; i++)
				[ma addObject:[NSString stringWithFormat:@"[,%d]", i+1]];
			self.columnNames = ma;
		}
		if (nil == self.rowNames) {
			NSMutableArray *ma = [NSMutableArray arrayWithCapacity:_rowCount];
			for (int i=0; i < _rowCount; i++)
				[ma addObject:[NSString stringWithFormat:@"[%d,]", i+1]];
			self.rowNames = ma;
		}
	}
	return self;
}


-(NSString*)valueAtRow:(int)row column:(int)col
{
	NSInteger idx = (row * _colCount) + col;
	id val = [self valueAtIndex:idx];
	switch (self.primitiveType) {
		case ePrimType_Boolean:
			return [val boolValue] ? @"TRUE" : @"FALSE";
		case ePrimType_Double:
			return [self.decFormatter stringFromNumber:val];
		case ePrimType_Null:
			return @"NULL";
		case ePrimType_NA:
			return @"NA";
		case ePrimType_Integer:
		case ePrimType_String:
		case ePrimType_Complex:
		case ePrimType_Raw:
		case ePrimType_Unknown:
			return [val description];
	}
}

@end
