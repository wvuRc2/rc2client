//
//  RCDataFrame.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/11/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCDataFrame.h"

@interface RCDataFrame ()
@property (readwrite) RCVariableType type;
@property (nonatomic, readwrite) NSInteger rowCount;
@property (nonatomic, readwrite) NSInteger colCount;
@property (nonatomic, strong) NSNumberFormatter *decFormatter;
@property (nonatomic, copy, readwrite) NSArray *columnNames;
@property (nonatomic, copy, readwrite) NSArray *rowNames;
@property (nonatomic, copy) NSArray *rowData;
@property (nonatomic, copy) NSArray *colTypes;
@end

@implementation RCDataFrame

-(id)initWithDictionary:(NSDictionary *)dict
{
	if ((self = [super initWithDictionary:dict])) {
		self.type = eVarType_DataFrame;
		self.rowCount = [[dict objectForKey:@"nrow"] longValue];
		self.columnNames = [dict objectForKey:@"cols"];
		self.colCount = self.columnNames.count;
		self.rowNames = [dict objectForKey:@"row.names"];
		self.rowData = [dict objectForKey:@"rows"];
		self.decFormatter = [[NSNumberFormatter alloc] init];
		self.decFormatter.positiveFormat = @"###0.####";
		self.decFormatter.maximumFractionDigits = 4;
		NSMutableArray *ma = [NSMutableArray arrayWithCapacity:self.colCount];
		for (NSString *ts in [dict objectForKey:@"types"]) {
			if ([ts isEqualToString:@"d"])
				[ma addObject:@(ePrimType_Double)];
			else if ([ts isEqualToString:@"i"])
				[ma addObject:@(ePrimType_Integer)];
			else if ([ts isEqualToString:@"b"])
				[ma addObject:@(ePrimType_Boolean)];
			else
				[ma addObject:@(ePrimType_String)];
		}
		self.colTypes = ma;
	}
	return self;
}

-(NSString*)valueAtRow:(int)row column:(int)col
{
	NSArray *rowA = [self.rowData objectAtIndex:row];
	id val = [rowA objectAtIndex:col];
	id returnVal=nil;
	switch ([[self.colTypes objectAtIndex:col] integerValue]) {
		case ePrimType_Boolean:
			returnVal = [val boolValue] ? @"TRUE" : @"FALSE"; break;
		case ePrimType_Double:
			returnVal = [self.decFormatter stringFromNumber:val]; break;
		case ePrimType_Null:
			returnVal = @"NULL"; break;
		case ePrimType_NA:
			returnVal =  @"NA"; break;
		case ePrimType_Integer:
		case ePrimType_String:
		case ePrimType_Complex:
		case ePrimType_Raw:
		case ePrimType_Unknown:
			returnVal = [val description]; break;
	}
	if (![returnVal isKindOfClass:[NSString class]])
		NSLog(@"Why, oh why?");
	return returnVal;
}


-(void)decodeSupportedObjects:(NSDictionary*)dict
{
}

-(NSInteger)count
{
	return self.rowCount;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"data frame(%d,%d)", (int)self.rowCount, (int)self.columnNames.count];;
}

-(NSString*)summary
{
	return [NSString stringWithFormat:@"data.frame with %d rows, cols=%@", (int)self.rowCount, [self.columnNames componentsJoinedByString:@", "]];
}

@end
