//
//  RCStudentAssignment.m
//  iPadClient
//
//  Created by Mark Lilback on 5/14/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCStudentAssignment.h"

@implementation RCStudentAssignment

- (id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		[self updateWithDictionary:dict];
	}
	return self;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.studentName = [dict objectForKey:@"student"];
	self.studentId = [dict objectForKey:@"ownerid"];
	self.turnedIn = [[dict objectForKey:@"turnedin"] boolValue];
	self.dueDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"duedate"] doubleValue] / 1000.0];
	self.grade = [dict objectForKey:@"grade"];
	self.files = [dict objectForKey:@"files"];
}

@synthesize studentId=_studentId;
@synthesize studentName=_studentName;
@synthesize assignment=_assignment;
@synthesize turnedIn=_turnedIn;
@synthesize grade=_grade;
@synthesize files=_files;
@synthesize dueDate=_dueDate;
@end
