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
@property (nonatomic) long rowCount;
@end

@implementation RCDataFrame

-(id)initWithDictionary:(NSDictionary *)dict
{
	if ((self = [super initWithDictionary:dict])) {
		self.type = eVarType_DataFrame;
		self.rowCount = [[dict objectForKey:@"nrow"] longValue];
		self.columnNames = [dict objectForKey:@"cols"];
	}
	return self;
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
	return [NSString stringWithFormat:@"data.frame with %ld rows, cols=%@", self.rowCount, [self.columnNames componentsJoinedByString:@", "]];
}

@end
