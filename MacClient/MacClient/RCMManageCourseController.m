//
//  RCMManageCourseController.m
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "RCMManageCourseController.h"
#import "RCCourse.h"

@implementation RCMManageCourseController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

@synthesize theCourse;

@end
