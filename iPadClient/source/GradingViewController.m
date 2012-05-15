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
#import "MBProgressHUD.h"

@interface GradingViewController ()
@property (nonatomic, strong) IBOutlet AMPickerPopover *classPicker;
@property (nonatomic, strong) IBOutlet UITableView *studentTableView;
@property (nonatomic, strong) IBOutlet AMPickerPopover *assignmentPicker;
@property (nonatomic, strong) IBOutlet AMPickerPopover *filePicker;
@property (nonatomic, strong) IBOutlet UISegmentedControl *qualifySegControl;
@property (nonatomic, strong) IBOutlet UIView *studentDetailsView;
@property (nonatomic, strong) IBOutlet UILabel *studentNameLabel;
@property (nonatomic, strong) IBOutlet UITextField *gradeField;
@property (nonatomic, strong) IBOutlet UIButton *pdfButton;
@property (nonatomic, strong) UIDocumentInteractionController *interactionController;
@property (nonatomic, copy) NSString *myCachePath;
@property (nonatomic, strong) NSArray *students;
@property (nonatomic, copy) NSSet *dueAssignmentIds;
@property (nonatomic, strong) RCStudentAssignment *selectedStudent;
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, strong) NSMutableDictionary *pdfUrlData;
@end

@implementation GradingViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	//FIXME: setup something to clear this cache
	self.myCachePath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"gradding/"];
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:self.myCachePath error:nil];
	if (![fm fileExistsAtPath:self.myCachePath]) {
		[fm createDirectoryAtPath:self.myCachePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	self.kvoTokens = [NSMutableSet set];
	self.classPicker.itemKey = @"name";
	self.assignmentPicker.itemKey = @"name";
	self.filePicker.itemKey = @"name";
	self.classPicker.items = [Rc2Server sharedInstance].classesTaught;
	__unsafe_unretained GradingViewController *blockSelf = self;
	self.classPicker.changeHandler = ^(id picker) {
		[blockSelf courseSelectionChanged];
	};
	[self.kvoTokens addObject:[self.assignmentPicker addObserverForKeyPath:@"selectedItem" task:^(id obj, id change) {
		[blockSelf assignmentSelectionChagned];
	}]];
	[self.kvoTokens addObject:[self.filePicker addObserverForKeyPath:@"selectedItem" task:^(id obj, id change)
	{
		[blockSelf FileSelectionChanged];
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

-(IBAction)editPdf:(id)sender
{
	NSDictionary *selectedFile = self.filePicker.selectedItem;
	NSString *fname = [NSString stringWithFormat:@"rc2g-%@#%@#%@#%@-%@.pdf", [self.classPicker.selectedItem courseId],
					   [self.assignmentPicker.selectedItem assignmentId], self.selectedStudent.studentId,
					   [selectedFile objectForKey:@"wsfileid"],
					   self.selectedStudent.studentName];
	NSString *fpath = [self.myCachePath stringByAppendingPathComponent:fname];
	if ([[NSFileManager defaultManager] fileExistsAtPath:fpath]) {
		[self showPdfPanel:fpath];
	} else {
		//need to fetch the file
		ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:[NSString stringWithFormat:@"file/%@", 
																					 [selectedFile objectForKey:@"fileid"]]];
		__weak ASIHTTPRequest *req = theReq;
		req.downloadDestinationPath = fpath;
		[req setCompletionBlock:^{
			[MBProgressHUD hideHUDForView:self.view animated:YES];
			if (req.responseStatusCode == 200) {
				[self showPdfPanel:fpath];
			} else {
				[UIAlertView showAlertWithTitle:@"Error Fetching file" message:@"unknwon error"];
			}
		}];
		[MBProgressHUD showHUDAddedTo:self.view animated:YES];
		[req startAsynchronous];
	}
}

-(void)showPdfPanel:(NSString*)fpath
{
	self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:fpath]];
	[self.interactionController presentOpenInMenuFromRect:self.pdfButton.frame inView:self.pdfButton animated:YES];
}

-(void)handleUrl:(NSURL*)url
{
	NSString *fname = [url.lastPathComponent stringByDeletingPathExtension];
	NSArray *parts = [fname componentsSeparatedByString:@"-"];
	if (parts.count > 2 && [[parts objectAtIndex:0] isEqualToString:@"rc2g"]) {
		NSArray *ids = [[parts objectAtIndex:1] componentsSeparatedByString:@"#"]; //courseId/assignId/wsfileId
		if (ids.count != 4) {
			[UIAlertView showAlertWithTitle:@"Invalid PDF" message:@"This pdf is not from an assignment"];
			return;
		}
		self.pdfUrlData = [NSMutableDictionary dictionaryWithObjectsAndKeys:url.path, @"path", ids, @"ids", nil];
		NSInteger cid = [[ids objectAtIndex:0] integerValue];
		for (RCCourse *course in self.classPicker.items) {
			if (course.courseId.integerValue == cid) {
				self.classPicker.selectedItem = course;
				break;
			}
		}
		NSInteger aid = [[ids objectAtIndex:1] integerValue];
		if ([[self.assignmentPicker.selectedItem assignmentId] integerValue] != aid) {
			for (RCAssignment *ass in self.assignmentPicker.items) {
				if ([ass.assignmentId integerValue] == aid) {
					self.assignmentPicker.selectedItem = ass;
					break;
				}
			}
		}
		NSInteger sid = [[ids objectAtIndex:2] integerValue];
		if (self.selectedStudent.studentId.integerValue != sid) {
			RCStudentAssignment *stud = [self.students firstObjectWithValue:[NSNumber numberWithInteger:sid] forKey:@"studentId"];
			if (stud) {
				self.selectedStudent = stud;
				[self.studentTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.students indexOfObject:stud] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
			}
		}
		NSInteger wsfid = [[ids objectAtIndex:3] integerValue];
		if ([[self.filePicker.selectedItem objectForKey:@"wsfileid"] integerValue] != wsfid) {
			self.filePicker.selectedItem = [self.filePicker.items firstObjectWithValue:[NSNumber numberWithInt:wsfid] forKey:@"wsfileid"];
		}
	}
	[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
	self.pdfUrlData=nil;
}

-(void)handleAssignmentServerResponse:(ASIHTTPRequest*)req
{
	RCCourse *course = self.classPicker.selectedItem;
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
}

-(void)courseSelectionChanged
{
	RCCourse *course = self.classPicker.selectedItem;
	if (course.assignments.count < 1) {
		//need to load them
		ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:
								  [NSString stringWithFormat:@"courses/%@", course.classId]];
		__unsafe_unretained ASIHTTPRequest *req = theReq;
		if (nil == self.pdfUrlData) {
			[theReq setCompletionBlock:^{
				[self handleAssignmentServerResponse:req];
			}];
			[req startAsynchronous];
		} else {
			[req startSynchronous];
			[self handleAssignmentServerResponse:req];
		}
	}
}

-(void)assignmentSelectionChagned
{
	self.selectedStudent=nil;
	RCAssignment *assignment = self.assignmentPicker.selectedItem;
	//need to fetch the list of student workspaces for selected assignment
	ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:
							  [NSString stringWithFormat:@"assignment/%@/grade", assignment.assignmentId]];
	__unsafe_unretained ASIHTTPRequest *req = theReq;
	if (nil == self.pdfUrlData) {
		[theReq setCompletionBlock:^{
			[self processStudentListResponse:req];
		}];
		[req startAsynchronous];
	} else {
		[req startSynchronous];
		[self processStudentListResponse:req];
	}
}

-(void)processStudentListResponse:(ASIHTTPRequest*)req
{
	if (req.responseStatusCode != 200) {
		[UIAlertView showAlertWithTitle:@"Error fetching data" message:@"unknown error from server"];
		self.students=nil;
		return;
	}
	NSDictionary *d = [req.responseString JSONValue];
	NSArray *studentList = [d objectForKey:@"workspaces"];
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:studentList.count];
	for (NSDictionary *d in studentList) {
		RCStudentAssignment *sa = [[RCStudentAssignment alloc] initWithDictionary:d];
		sa.assignment = self.assignmentPicker.selectedItem;
		[ma addObject:sa];
	}
	self.students = ma;
	[self.studentTableView reloadData];
}

-(void)FileSelectionChanged
{
	NSDictionary *fileData = self.filePicker.selectedItem;
	[self.pdfButton setEnabled: [[fileData objectForKey:@"name"] hasSuffix:@".pdf"]];
}

-(void)adjustStudentDetails
{
	if (self.selectedStudent) {
		[UIView animateWithDuration:0.3 animations:^{
			self.studentDetailsView.alpha = 1;
		}];
		self.studentNameLabel.text = self.selectedStudent.studentName;
		self.gradeField.text = self.selectedStudent.grade.description;
		self.filePicker.items = self.selectedStudent.files;
	} else {
		[UIView animateWithDuration:0.3 animations:^{
			self.studentDetailsView.alpha = 0;
		}];
		if (self.gradeField.isFirstResponder)
			[self.gradeField resignFirstResponder];
	}
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
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
@synthesize filePicker=_filePicker;
@synthesize pdfButton=_pdfButton;
@synthesize myCachePath=_myCachePath;
@synthesize interactionController=_interactionController;
@synthesize pdfUrlData=_pdfUrlData;
@end
