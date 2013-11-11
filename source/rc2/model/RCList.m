//
//  RCList.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/11/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCList.h"

@interface RCList ()
@property (nonatomic, copy) NSArray *names;
@end

@implementation RCList

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super initWithDictionary:dict])) {
		NSMutableArray *listVals = [NSMutableArray arrayWithCapacity:[dict[@"length"] integerValue]];
		for (NSDictionary *anItem in dict[@"value"]) {
			[listVals addObject:[RCVariable variableWithDictionary:anItem]];
		}
		self.names = dict[@"names"];
		if (self.names.count == 1 && self.names[0] == [NSNull null])
			self.names = nil;
		self.values = listVals;
	}
	return self;
}

-(NSString*)nameAtIndex:(NSUInteger)index
{
	if (nil == self.names || self.names.count <= index)
		return @"";
	return self.names[index];
}
	
-(BOOL)hasNames
{
	return nil != self.names && self.names.count > 0;
}

@end
