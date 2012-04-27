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
@property (nonatomic, strong) IBOutlet NSArrayController *assignmentController;
@property (nonatomic, strong) IBOutlet NSTableView *assignTable;
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, strong) id curSelToken;
@property (nonatomic, strong) RCAssignment *selectedAssignment;
@property (nonatomic, strong) NSIndexSet *selIndexes;
@end

@implementation RCMManageCourseController

-(id)init
{
 	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.kvoTokens = [NSMutableSet set];
	}
	return self;
}

-(void)awakeFromNib
{
	__unsafe_unretained RCMManageCourseController *blockSelf = self;
	[self.kvoTokens addObject:[self.assignmentController addObserverForKeyPath:@"selectedObjects" task:^(id obj, NSDictionary *change) {
		blockSelf.selectedAssignment = [[obj selectedObjects] firstObject];
	}]];
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
			self.theCourse.assignments = [RCAssignment assignmentsFromJSONArray:[rsp objectForKey:@"assignments"] forCourse:self.theCourse];
		}
	}];
	[req startAsynchronous];
}

- (BOOL)control:(NSControl *)control isValidObject:(id)object
{
	NSInteger colNum = [self.assignTable.tableColumns indexOfObject:[self.assignTable tableColumnWithIdentifier:@"name"]];
	NSInteger rowNum = [self.assignmentController.arrangedObjects indexOfObject:self.selectedAssignment];
	NSView *dispView = [self.assignTable viewAtColumn:colNum row:rowNum makeIfNecessary:NO];
	if ([control isDescendantOf:dispView]) {
		//it is the name view
		return [[Rc2Server sharedInstance] synchronouslyUpdateAssignment:self.selectedAssignment withValues:[NSDictionary dictionaryWithObject:object forKey:@"name"]];
	}
	return YES;
}

-(void)setSelectedAssignment:(RCAssignment *)assign
{
	if (assign == _selectedAssignment)
		return;
	self.curSelToken = [assign addObserverForKeyPath:@"name" task:^(id obj, NSDictionary *change) {
//		NSLog(@"name changed: %@, %@", [obj name], change);
	}];
	_selectedAssignment = assign;
}

@synthesize theCourse=_theCourse;
@synthesize kvoTokens=_kvoTokens;
@synthesize assignmentController=_assignmentController;
@synthesize selectedAssignment=_selectedAssignment;
@synthesize curSelToken=_curSelToken;
@synthesize selIndexes=_selIndexes;
@synthesize assignTable=_assignTable;
@end
