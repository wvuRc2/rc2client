//
//  RCAssignment.m
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCAssignment.h"

@implementation RCAssignment

+(NSArray*)assignmentsFromJSONArray:(NSArray*)json
{
	if ([json count] < 1)
		return nil;
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:json.count];
	for (NSDictionary *cd in json) {
		RCAssignment *ass = [[RCAssignment alloc] initWithDictionary:cd];
		[a addObject:ass];
	}
	return a;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	self.assignmentId = [dict objectForKey:@"id"];
	[self updateWithDictionary:dict];
	return self;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.name = [dict objectForKey:@"name"];
	self.sortOrder = [dict objectForKey:@"sortOrder"];
	self.locked = [[dict objectForKey:@"locked"] boolValue];
	self.startDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"startDate"] integerValue]];
	self.endDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"endDate"] integerValue]];
}

@synthesize assignmentId;
@synthesize sortOrder;
@synthesize name;
@synthesize locked;
@synthesize startDate;
@synthesize endDate;
@end
