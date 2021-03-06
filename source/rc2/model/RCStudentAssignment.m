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
	self.workspaceId = [dict objectForKey:@"id"];
	self.studentName = [dict objectForKey:@"student"];
	self.studentId = [dict objectForKey:@"ownerid"];
	self.turnedIn = [[dict objectForKey:@"turnedin"] boolValue];
	self.dueDate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"duedate"] doubleValue] / 1000.0];
	self.grade = [dict objectForKey:@"grade"];
	NSMutableArray *files = [[[dict objectForKey:@"files"] mutableCopy] deepCopy];
	for (NSMutableDictionary *aFile in files) {
		if ([[aFile objectForKey:@"kind"] isEqualToString:@"graded"]) {
			NSString *fname = [aFile objectForKey:@"name"];
			[aFile setObject:[[[fname stringByDeletingPathExtension] stringByAppendingString:@" (Graded)"] stringByAppendingPathExtension:[fname pathExtension]] forKey:@"name"];
		}
	}
	self.files = files;
}

@synthesize studentId=_studentId;
@synthesize studentName=_studentName;
@synthesize assignment=_assignment;
@synthesize turnedIn=_turnedIn;
@synthesize grade=_grade;
@synthesize files=_files;
@synthesize dueDate=_dueDate;
@synthesize workspaceId=_workspaceId;
@end
