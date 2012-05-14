//
//  GradingViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "GradingViewController.h"
#import "ThemeEngine.h"
#import "Vyana-ios/AMPickerPopover.h"
#import "Rc2Server.h"
#import "RCCourse.h"
#import "RCAssignment.h"
#import "RCStudentAssignment.h"
#import "StudentAssignmentCell.h"
#import "ASIFormDataRequest.h"

@interface GradingViewController ()
@property (nonatomic, strong) IBOutlet AMPickerPopover *classPicker;
@property (nonatomic, strong) IBOutlet UITableView *studentTableView;
@property (nonatomic, strong) IBOutlet AMPickerPopover *assignmentPicker;
@property (nonatomic, strong) IBOutlet UISegmentedControl *qualifySegControl;
@property (nonatomic, strong) IBOutlet UIView *studentDetailsView;
@property (nonatomic, strong) IBOutlet UILabel *studentNameLabel;
@property (nonatomic, strong) IBOutlet UITextField *gradeField;
@property (nonatomic, strong) NSArray *students;
@property (nonatomic, copy) NSSet *dueAssignmentIds;
@property (nonatomic, strong) RCStudentAssignment *selectedStudent;
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@end

@implementation GradingViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.kvoTokens = [NSMutableSet set];
	self.classPicker.itemKey = @"name";
	self.assignmentPicker.itemKey = @"name";
	self.classPicker.items = [Rc2Server sharedInstance].classesTaught;
	__unsafe_unretained GradingViewController *blockSelf = self;
	self.classPicker.changeHandler = ^(id picker) {
		[blockSelf courseSelectionChanged];
	};
	[self.kvoTokens addObject:[self.assignmentPicker addObserverForKeyPath:@"selectedItem" task:^(id obj, id change) {
		[blockSelf assignmentSelectionChagned];
	}]];
	//parse the tograde list to know which assignments are due
	NSArray *tograde = [Rc2Server sharedInstance].assignmentsToGrade;
	NSMutableSet *dueAssignments = [NSMutableSet set];
	for (NSDictionary *d in tograde) {
		[dueAssignments addObject:[d objectForKey:@"assignid"]];
	}
	self.dueAssignmentIds = dueAssignments;
	[self courseSelectionChanged]; //trigger initial load of assignments
	self.studentDetailsView.alpha = 0;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(IBAction)qualifierValueChanged:(id)sender
{
	
}

-(void)courseSelectionChanged
{
	RCCourse *course = self.classPicker.selectedItem;
	if (course.assignments.count < 1) {
		//need to load them
		ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:
								  [NSString stringWithFormat:@"courses/%@", course.classId]];
		__unsafe_unretained ASIHTTPRequest *req = theReq;
		[theReq setCompletionBlock:^{
			NSDictionary *rsp = [req.responseString JSONValue];
			if ([[rsp objectForKey:@"status"] intValue] == 0) {
				course.assignments = [RCAssignment assignmentsFromJSONArray:[rsp objectForKey:@"assignments"] forCourse:course];
				if (self.qualifySegControl.selectedSegmentIndex == 0) {
					NSMutableArray *ma = [NSMutableArray array];
					for (RCAssignment *ass in course.assignments) {
						if ([self.dueAssignmentIds containsObject: ass.assignmentId])
							[ma addObject: ass];
					}
					self.assignmentPicker.items = ma;
				} else {
					self.assignmentPicker.items = course.assignments;
				}
			}
		}];
		[req startAsynchronous];
	}
}

-(void)assignmentSelectionChagned
{
	RCAssignment *assignment = self.assignmentPicker.selectedItem;
	//need to fetch the list of student workspaces for selected assignment
	ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:
							  [NSString stringWithFormat:@"assignment/%@/grade", assignment.assignmentId]];
	__unsafe_unretained ASIHTTPRequest *req = theReq;
	[theReq setCompletionBlock:^{
		if (req.responseStatusCode == 200) {
			NSDictionary *d = [req.responseString JSONValue];
			if (d)
				[self processStudentList:[d objectForKey:@"workspaces"]];
		}
	}];
	[req startAsynchronous];
}

-(void)processStudentList:(NSArray*)studentList
{
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:studentList.count];
	for (NSDictionary *d in studentList) {
		RCStudentAssignment *sa = [[RCStudentAssignment alloc] initWithDictionary:d];
		sa.assignment = self.assignmentPicker.selectedItem;
		[ma addObject:sa];
	}
	self.students = ma;
	[self.studentTableView reloadData];
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}

-(void)adjustStudentDetails
{
	if (self.selectedStudent) {
		[UIView animateWithDuration:0.3 animations:^{
			self.studentDetailsView.alpha = 1;
		}];
		self.studentNameLabel.text = self.selectedStudent.studentName;
		self.gradeField.text = self.selectedStudent.grade.description;
	} else {
		[UIView animateWithDuration:0.3 animations:^{
			self.studentDetailsView.alpha = 0;
		}];
		if (self.gradeField.isFirstResponder)
			[self.gradeField resignFirstResponder];
	}
}

#pragma mark - text field

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (string.length > 0) {
		static NSCharacterSet *cset;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			cset = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
		});
		if ([string containsCharacterNotInSet:cset])
			return NO;
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	//TODO: save the grade
	return NO;
}

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.students.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	StudentAssignmentCell *cell = [StudentAssignmentCell cellForTableView:tableView];
	cell.student = [self.students objectAtIndex:indexPath.row];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id newStudent = [self.students objectAtIndex:indexPath.row];
	if (newStudent == self.selectedStudent) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		self.selectedStudent=nil;
	} else {
		self.selectedStudent = newStudent;
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 100;
}

-(void)setSelectedStudent:(RCStudentAssignment *)sel
{
	_selectedStudent=sel;
	[self adjustStudentDetails];
}

@synthesize classPicker=_classPicker;
@synthesize assignmentPicker=_assignmentPicker;
@synthesize qualifySegControl=_qualifySegControl;
@synthesize dueAssignmentIds=_dueAssignmentIds;
@synthesize studentTableView=_studentTableView;
@synthesize students=_students;
@synthesize kvoTokens=_kvoTokens;
@synthesize selectedStudent=_selectedStudent;
@synthesize studentDetailsView=_studentDetailsView;
@synthesize studentNameLabel=_studentNameLabel;
@synthesize gradeField=_gradeField;
@end
