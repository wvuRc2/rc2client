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
#import "ASIFormDataRequest.h"

@interface GradingViewController ()
@property (nonatomic, strong) IBOutlet AMPickerPopover *classPicker;
@property (nonatomic, strong) IBOutlet AMPickerPopover *assignmentPicker;
@property (nonatomic, strong) IBOutlet UISegmentedControl *qualifySegControl;
@property (nonatomic, copy) NSSet *dueAssignmentIds;
@end

@implementation GradingViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.classPicker.itemKey = @"name";
	self.assignmentPicker.itemKey = @"name";
	self.classPicker.items = [Rc2Server sharedInstance].classesTaught;
	__unsafe_unretained GradingViewController *blockSelf = self;
	self.classPicker.changeHandler = ^(id picker) {
		[blockSelf courseSelectionChanged];
	};
	self.assignmentPicker.changeHandler = ^(id picker) {
		[blockSelf assignmentSelectionChagned];
	};
	//parse the tograde list to know which assignments are due
	NSArray *tograde = [Rc2Server sharedInstance].assignmentsToGrade;
	NSMutableSet *dueAssignments = [NSMutableSet set];
	for (NSDictionary *d in tograde) {
		[dueAssignments addObject:[d objectForKey:@"assignid"]];
	}
	self.dueAssignmentIds = dueAssignments;
	[self courseSelectionChanged]; //trigger initial load of assignments
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
	
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}

@synthesize classPicker=_classPicker;
@synthesize assignmentPicker=_assignmentPicker;
@synthesize qualifySegControl=_qualifySegControl;
@synthesize dueAssignmentIds=_dueAssignmentIds;
@end
