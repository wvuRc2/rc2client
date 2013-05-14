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
@property (nonatomic, strong) IBOutlet NSArrayController *semesterController;
@property (nonatomic, strong) IBOutlet NSArrayController *courseController;
@property (nonatomic, strong) IBOutlet NSArrayController *instructorController;
@property (nonatomic, strong) IBOutlet NSArrayController *instanceController;
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
			self.semesterController.content = [results objectForKey:@"semesters"];
			self.courseController.content = [results objectForKey:@"courses"];
			self.instanceController.content = [results objectForKey:@"instances"];
			self.instructorController.content = [results objectForKey:@"instructors"];
		} else {
			Rc2LogError(@"failed to fetch courses");
		}
	}];
}

@end
