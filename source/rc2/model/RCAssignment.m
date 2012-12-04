//
//  RCAssignment.m
//  Rc2Client
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCAssignment.h"
#import "RCAssignmentFile.h"

@implementation RCAssignment

+(NSArray*)assignmentsFromJSONArray:(NSArray*)json forCourse:(RCCourse*)course
{
	if ([json count] < 1)
		return nil;
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:json.count];
	for (NSDictionary *cd in json) {
		RCAssignment *ass = [[RCAssignment alloc] initWithDictionary:cd];
		ass.course = course;
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
	self.startDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"startDate"] integerValue]/1000];
	self.endDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"endDate"] integerValue]/1000];
	id files = [dict objectForKey:@"assignmentFiles"];
	if ([files isKindOfClass:[NSArray class]])
		self.files = [RCAssignmentFile filesFromJSONArray:files forCourse:self];
}

@synthesize assignmentId;
@synthesize sortOrder;
@synthesize name=_name;
@synthesize locked;
@synthesize startDate;
@synthesize endDate;
@synthesize course=_course;
@synthesize files=_files;
@end
