//
//  RCCourse.m
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCCourse.h"

@implementation RCCourse

+(NSArray*)classesFromJSONArray:(NSArray*)json
{
	if ([json count] < 1)
		return [NSArray array];
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:json.count];
	for (NSDictionary *cd in json) {
		RCCourse *aClass = [[RCCourse alloc] initWithDictionary:cd];
		[a addObject:aClass];
	}
	return a;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	self.classId = [dict objectForKey:@"id"];
	[self updateWithDictionary:dict];
	return self;
}

-(void)updateWithDictionary:(NSDictionary*)dict;
{
	self.courseId = [dict objectForKey:@"courseId"];
	self.semesterId = [dict objectForKey:@"semesterId"];
	self.semesterName = [dict objectForKey:@"semester"];
	self.courseName = [dict objectForKey:@"courseName"];
	self.name = [dict objectForKey:@"name"];
}

@synthesize classId;
@synthesize courseId;
@synthesize semesterId;
@synthesize semesterName;
@synthesize courseName;
@synthesize name;
@synthesize assignments;
@end
