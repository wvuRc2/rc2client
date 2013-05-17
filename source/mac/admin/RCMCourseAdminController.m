//
//  RCMCourseAdminController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "RCMCourseAdminController.h"
#import "Rc2Server.h"
#import "MAKVONotificationCenter.h"

@interface RCMCourseAdminController ()
@property (nonatomic, copy) NSArray *semesters;
@property (nonatomic, copy) NSArray *courses;
@property (nonatomic, copy) NSArray *instances;
@property (nonatomic, strong) IBOutlet NSArrayController *semesterController;
@property (nonatomic, strong) IBOutlet NSArrayController *courseController;
@property (nonatomic, strong) IBOutlet NSArrayController *instructorController;
@property (nonatomic, strong) IBOutlet NSArrayController *instanceController;
@property (nonatomic, strong) IBOutlet NSArrayController *searchResultsController;
@property (nonatomic, strong) IBOutlet NSArrayController *studentsController;
@property (nonatomic, copy) NSString *searchString;
@property (nonatomic, strong) IBOutlet NSWindow *addDialog;
@property (nonatomic, strong) NSRecursiveLock *requestLock;
@property (copy) NSString *requestId;
@property (copy) NSArray *searchResults;
-(void)fetchStudents;
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
	self.requestLock = [[NSRecursiveLock alloc] init];
	[[Rc2Server sharedInstance] fetchCourses:^(BOOL success, id results) {
		if (success) {
			[self loadCourses:results];
		} else {
			Rc2LogError(@"failed to fetch courses");
		}
	}];
	[self observeTarget:self.courseController keyPath:@"selection" options:0 block:^(MAKVONotification *notification) {
		[notification.observer fetchStudents];
	}];
}

-(void)fetchStudents
{
	NSDictionary *course = self.courseController.selectedObjects.firstObject;
	if (nil == course)
		self.studentsController.content = @[];
	else {
		[[Rc2Server sharedInstance] fetchCourseStudents:[course objectForKey:@"id"] completionHandler:^(BOOL success, id results) {
			self.studentsController.content = [[results objectForKey:@"students"] mutableCopy];
		}];
	}
}

-(IBAction)searchUsers:(id)sender
{
	if (_searchString.length < 1) {
		self.searchResultsController.content = [NSArray array];
		return;
	}
	[self.requestLock lock];
	NSString *rid = [NSString stringWithUUID];
	self.requestId = rid;
	__weak RCMCourseAdminController *bself = self;
	[[Rc2Server sharedInstance] searchUsers:@{@"type":@"all", @"value":_searchString} completionHandler:^(BOOL success, id results)
	 {
		 [bself.requestLock lock];
		 //only if we are the most recent request
		 if ([bself.requestId isEqualToString:rid]) {
			 self.searchResults = [results objectForKey:@"users"];
		 }
		 [bself.requestLock unlock];
	 }];
	[self.requestLock unlock];
}

-(IBAction)addToClass:(id)sender
{
	if (![sender isKindOfClass:[NSArray class]])
		sender = self.searchResultsController.selectedObjects;
	NSLog(@"addToClass:%@", sender);
}

-(IBAction)removeFromClass:(id)sender
{
	
}

-(void)loadCourses:(id)results
{
	self.semesterController.content = [[results objectForKey:@"semesters"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortorder" ascending:NO]]];
	self.courseController.content = [[results objectForKey:@"courses"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"shortname" ascending:YES]]];
	self.instanceController.content = [results objectForKey:@"instances"];
	self.instructorController.content = [results objectForKey:@"instructors"];
	
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
}

-(IBAction)showAddDialog:(id)sender
{
	[NSApp beginSheet:self.addDialog modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)addTheClass:(id)sender
{
	[NSApp endSheet:self.addDialog returnCode:NSOKButton];
	NSDictionary *params = @{@"course": [self.courseController.selection valueForKey:@"id"],
						  @"semester": [self.semesterController.selection valueForKey:@"id"],
						  @"instructor": [self.instructorController.selection valueForKey:@"id"]};
	[[Rc2Server sharedInstance] addCourse:params completionHandler:^(BOOL success, id results) {
		if (success) {
			[self loadCourses:results];
		} else {
			[NSAlert displayAlertWithTitle:@"Error adding Class" details:results window:self.view.window];
		}
	}];
}

-(IBAction)cancelDialog:(id)sender
{
	[NSApp endSheet:self.addDialog returnCode:NSCancelButton];
}

@end
