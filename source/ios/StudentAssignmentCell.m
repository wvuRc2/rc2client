//
//  StudentAssignmentCell.m
//  iPadClient
//
//  Created by Mark Lilback on 5/14/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "StudentAssignmentCell.h"
#import "RCStudentAssignment.h"

@interface StudentAssignmentCell ()
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *turnedInLabel;
@property (nonatomic, strong) IBOutlet UILabel *gradeLabel;

@end

@implementation StudentAssignmentCell

-(void)setStudent:(RCStudentAssignment *)st
{
	static NSDateFormatter *dfmt;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dfmt = [[NSDateFormatter alloc] init];
		dfmt.dateStyle = NSDateFormatterShortStyle;
		dfmt.timeStyle = NSDateFormatterShortStyle;
	});
	_student = st;
	self.nameLabel.text = st.studentName;
	self.turnedInLabel.text = st.turnedIn ? @"yes" : @"no";
	self.dateLabel.text = [dfmt stringFromDate:st.dueDate];
	self.gradeLabel.text = [st.grade description];
}

@end
