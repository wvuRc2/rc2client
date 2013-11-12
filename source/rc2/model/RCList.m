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
		[self assignListData:dict];
	}
	return self;
}

-(void)assignListData:(NSDictionary*)dict
{
	NSMutableArray *listVals = [NSMutableArray arrayWithCapacity:[dict[@"length"] integerValue]];
	NSArray *dictValues = dict[@"value"];
	if (dictValues) {
		[dictValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *aDict = obj;
			if ([[aDict objectForKey:@"name"] isKindOfClass:[NSNull class]]) {
				NSMutableDictionary *mdict = [aDict mutableCopy];
				if (self.hasNames)
					[mdict setObject:[self nameAtIndex:idx] forKey:@"name"];
				else
					[mdict setObject:[NSString stringWithFormat:@"%@[%lu]", self.name, (unsigned long)idx+1] forKey:@"name"];
				aDict = mdict;
			}
			RCVariable *aVar = [RCVariable variableWithDictionary:aDict];
			aVar.parentList = self;
			[listVals addObject:aVar];
		}];
		self.values = listVals;
	}
	self.names = dict[@"names"];
	if (self.names.count == 1 && self.names[0] == [NSNull null])
		self.names = nil;
}

-(NSInteger)indexOfVariable:(RCVariable*)var
{
	return [self.values indexOfObject:var];
}

-(NSString*)fullyQualifiedName
{
	if (nil == self.parentList)
		return self.name;
	return [NSString stringWithFormat:@"%@[%ld]", self.parentList.fullyQualifiedName, (unsigned long)[self.parentList indexOfVariable:self]+1];
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

-(BOOL)hasValues
{
	return self.values != nil;
}
@end
