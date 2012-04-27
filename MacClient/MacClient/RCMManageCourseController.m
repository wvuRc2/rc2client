//
//  RCMManageCourseController.m
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "RCMManageCourseController.h"
#import "RCCourse.h"
#import "RCAssignment.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

@interface RCMManageCourseController()
@end

@implementation RCMManageCourseController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	if (self.theCourse.assignments.count < 1)
		[self loadAssignments];
}

#pragma mark - meat & potatos

-(void)loadAssignments
{
	ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:
							  [NSString stringWithFormat:@"courses/%@", self.theCourse.classId]];
	__unsafe_unretained ASIHTTPRequest *req = theReq;
	[theReq setCompletionBlock:^{
		NSDictionary *rsp = [req.responseString JSONValue];
		if ([[rsp objectForKey:@"status"] intValue] == 0) {
			self.theCourse.assignments = [RCAssignment assignmentsFromJSONArray:[rsp objectForKey:@"assignments"]];
		}
	}];
	[req startAsynchronous];
}

@synthesize theCourse;

@end
