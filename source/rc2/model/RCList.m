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
		[dict[@"value"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *aDict = obj;
			if (nil == [aDict objectForKey:@"name"]) {
				NSMutableDictionary *mdict = [aDict mutableCopy];
				if (self.hasNames)
					[mdict setObject:[self nameAtIndex:idx] forKey:@"name"];
				else
					[mdict setObject:[NSString stringWithFormat:@"%@[%lu]", self.name, (unsigned long)idx+1] forKey:@"name"];
				aDict = mdict;
			}
			RCVariable *aVar = [RCVariable variableWithDictionary:aDict];
			[listVals addObject:aVar];
		}];
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
