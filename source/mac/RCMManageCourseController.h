//
//  RCMManageCourseController.h
//  MacClient
//
//  Created by Mark Lilback on 4/27/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "MCAbstractViewController.h"

@class RCCourse;

@interface RCMManageCourseController : MCAbstractViewController<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, strong) RCCourse *theCourse;
@end
