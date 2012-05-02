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
#import "RCAssignmentFile.h"
#import "Rc2Server.h"
#import "ASIFormDataRequest.h"

@interface RCMManageCourseController()
@property (nonatomic, strong) IBOutlet NSArrayController *assignmentController;
@property (nonatomic, strong) IBOutlet NSTableView *assignTable;
@property (nonatomic, strong) IBOutlet NSTableView *fileTable;
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, strong) id curSelToken;
@property (nonatomic, strong) RCAssignment *selectedAssignment;
@property (nonatomic, strong) RCAssignmentFile *selectedFile;
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

#pragma mark - actions

-(IBAction)uploadFiles:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:[Rc2Server acceptableImportFileSuffixes]];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (NSFileHandlingPanelCancelButton == result)
			return;
		//need to perform the actual uploads in the background
		self.busy = YES;
		self.statusMessage = @"Uploading files";
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self importFiles:openPanel.URLs];
		});
	}];
}

-(IBAction)deleteFile:(id)sender
{
	NSString *errorMessage=nil;
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:[NSString stringWithFormat:@"assignment/%@/file/%@", self.selectedAssignment.assignmentId, self.selectedFile.assignmentFileId]];
	[req setRequestMethod:@"DELETE"];
	[req startSynchronous];
	if (req.responseStatusCode != 200) {
		errorMessage = @"server error deleting file";
	} else {
		NSDictionary *d = [req.responseString JSONValue];
		if ([[d objectForKey:@"status"] intValue] != 0) {
			errorMessage = [d objectForKey:@"message"];
		} else {
			[self.selectedAssignment updateWithDictionary:[d objectForKey:@"assignment"]];
			[self.fileTable reloadData];
		}
	}
}

#pragma mark - meat & potatos

-(void)importFiles:(NSArray*)fileUrls
{
	NSString *errorMessage=nil;
	NSString *uploadUrl = [NSString stringWithFormat:@"assignment/%@/file", self.selectedAssignment.assignmentId];
	for (NSURL *fileUrl in fileUrls) {
		ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:uploadUrl];
		[req setFile:fileUrl.path forKey:@"content"];
		[req setPostValue:fileUrl.path.lastPathComponent forKey:@"name"];
		[req startSynchronous];
		if (req.responseStatusCode != 200) {
			errorMessage = @"server error uploading file";
			break;
		}
		NSDictionary *dict = [req.responseString JSONValue];
		if ([[dict objectForKey:@"status"] intValue] != 0) {
			errorMessage = [dict objectForKey:@"message"];
			break;
		}
		[self.selectedAssignment updateWithDictionary:[dict objectForKey:@"assignment"]];
		[self.fileTable reloadData];
	}
	if (errorMessage)
		[NSAlert displayAlertWithTitle:@"Unknown Error" details:errorMessage];
	//when finished
	dispatch_async(dispatch_get_main_queue(), ^{
		self.busy=NO;
		self.statusMessage=@"";
	});
}

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

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.fileTable) {
		return self.selectedAssignment.files.count;
	}
	return 0;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == self.fileTable) {
		RCAssignmentFile *file = [self.selectedAssignment.files objectAtIndex:row];
		if ([tableColumn.identifier isEqualToString:@"name"])
			return file.name;
		if ([tableColumn.identifier isEqualToString:@"readonly"])
			return [NSNumber numberWithBool:file.readonly];
	}
	return nil;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView != self.fileTable)
		return;
	if (![tableColumn.identifier isEqualToString:@"readonly"]) {
		NSBeep();
		return;
	}
	if (self.selectedAssignment.locked) {
		NSBeep();
		return;
	}
	RCAssignmentFile *afile = [self.selectedAssignment.files objectAtIndex:row];
	//send to server
	NSString *urlstr = [NSString stringWithFormat:@"assignment/%@/file/%@", self.selectedAssignment.assignmentId, afile.assignmentFileId];
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:urlstr];
	[req setRequestMethod:@"PUT"];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	NSDictionary *d = [NSDictionary dictionaryWithObject:object forKey:@"readonly"];
	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req startSynchronous];
	if (req.responseStatusCode == 200) {
		d = [req.responseString JSONValue];
		if ([[d objectForKey:@"status"] intValue] == 0) {
			afile.readonly = [object boolValue];
		}
	}
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger idx = [self.fileTable selectedRow];
	self.selectedFile = [self.selectedAssignment.files objectAtIndexNoExceptions:idx];
}

-(void)setSelectedAssignment:(RCAssignment *)assign
{
	if (assign == _selectedAssignment)
		return;
	self.curSelToken = [assign addObserverForKeyPath:@"name" task:^(id obj, NSDictionary *change) {
//		NSLog(@"name changed: %@, %@", [obj name], change);
	}];
	_selectedAssignment = assign;
	[self.fileTable reloadData];
}

@synthesize theCourse=_theCourse;
@synthesize kvoTokens=_kvoTokens;
@synthesize assignmentController=_assignmentController;
@synthesize selectedAssignment=_selectedAssignment;
@synthesize curSelToken=_curSelToken;
@synthesize selIndexes=_selIndexes;
@synthesize assignTable=_assignTable;
@synthesize fileTable=_fileTable;
@synthesize selectedFile=_selectedFile;
@end
