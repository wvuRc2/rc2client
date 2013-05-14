//
//  RCMCourseAdminController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "RCMCourseAdminController.h"
#import "Rc2Server.h"

@interface RCMCourseAdminController ()
@property (nonatomic, copy) NSArray *semesters;
@property (nonatomic, copy) NSArray *courses;
@property (nonatomic, copy) NSArray *instances;
@end

@implementation RCMCourseAdminController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[[Rc2Server sharedInstance] fetchCourses:^(BOOL success, id results) {
		if (success) {
			self.semesters = [results objectForKey:@"semesters"];
			self.courses = [results objectForKey:@"courses"];
			self.instances = [results objectForKey:@"instances"];
		} else {
			Rc2LogError(@"failed to fetch courses");
		}
	}];
}

@end
