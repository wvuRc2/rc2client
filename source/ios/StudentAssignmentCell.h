//
//  StudentAssignmentCell.h
//  iPadClient
//
//  Created by Mark Lilback on 5/14/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCStudentAssignment;

@interface StudentAssignmentCell : iAMTableViewCell
@property (nonatomic, strong) RCStudentAssignment *student;
@end
