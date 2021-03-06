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
#import "MultiFileImporter.h"

@interface RCMManageCourseController()
@property (nonatomic, strong) NSMutableArray *assignments;
@property (nonatomic, strong) NSMutableArray *students;
@property (nonatomic, strong) NSArray *assignSortDescriptors;
@property (nonatomic, strong) IBOutlet NSTableView *assignTable;
@property (nonatomic, strong) IBOutlet NSTableView *fileTable;
@property (nonatomic, strong) IBOutlet NSTableView *studentTable;
@property (nonatomic, strong) id curSelToken;
@property (nonatomic, strong) RCAssignment *selectedAssignment;
@property (nonatomic, strong) RCAssignmentFile *selectedFile;
@end

@implementation RCMManageCourseController

-(id)init
{
 	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.assignSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
		self.students = [NSMutableArray array];
	}
	return self;
}

-(void)awakeFromNib
{
	if (self.theCourse.assignments.count < 1)
		[self loadAssignments];
	[self.fileTable setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleRegular];
	[self.fileTable registerForDraggedTypes:ARRAY((id)kUTTypeFileURL)];
}

#pragma mark - actions

-(IBAction)addAssignment:(id)sender
{
//	NSString *aname = [NSString stringWithFormat:@"Assignment %ld", self.assignments.count + 1];
//	NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:86400 * 7];
//	NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:86400 * 14];
//	if (self.assignments.count > 0) {
//		RCAssignment *ass = [self.assignments lastObject];
//		startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:ass.endDate.timeIntervalSinceReferenceDate + 86400];
//		endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:startDate.timeIntervalSinceReferenceDate + 7 * 86400];
//	}
//	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:aname, @"name", 
//						  [NSNumber numberWithDouble:startDate.timeIntervalSince1970 * 1000], @"startDate", 
//						  [NSNumber numberWithDouble:endDate.timeIntervalSince1970 * 1000], @"endDate", nil];
//	ASIFormDataRequest *req = [RC2_SharedInstance() postRequestWithRelativeURL:[NSString stringWithFormat:@"courses/%@/assignment", self.theCourse.courseId]];
//	[req appendPostData:[[args JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
//	[req startSynchronous];
//	if (req.responseStatusCode != 200) {
//		[NSAlert displayAlertWithTitle:@"Server Error" details:[NSString stringWithFormat:@"server returned %d", req.responseStatusCode]];
//		return;
//	}
//	NSDictionary *dict = [req.responseString JSONValue];
//	if ([[dict objectForKey:@"status"] intValue] != 0) {
//		[NSAlert displayAlertWithTitle:@"Server Error" details:[dict objectForKey:@"message"]];
//		return;
//	}
//	RCAssignment *assign = [[RCAssignment alloc] initWithDictionary:[dict objectForKey:@"assignment"]];
//	[self.assignments addObject:assign];
//	[self.assignTable reloadData];
//	[self.assignTable selectRowIndexes:[NSIndexSet indexSetWithIndex:self.assignments.count-1] byExtendingSelection:NO];
}

-(IBAction)deleteAssignment:(id)sender
{
//	ASIHTTPRequest *req = [RC2_SharedInstance() requestWithRelativeURL:[NSString stringWithFormat:@"courses/%@/assignment/%@", self.theCourse.courseId, self.selectedAssignment.assignmentId]];
//	[req setRequestMethod:@"DELETE"];
//	[req startSynchronous];
//	if (req.responseStatusCode != 200) {
//		[NSAlert displayAlertWithTitle:@"Server Error" details:[NSString stringWithFormat:@"server returned %d", req.responseStatusCode]];
//		return;
//	}
//	NSDictionary *dict = [req.responseString JSONValue];
//	if ([[dict objectForKey:@"status"] intValue] != 0) {
//		[NSAlert displayAlertWithTitle:@"Server Error" details:[dict objectForKey:@"message"]];
//		return;
//	}
//	NSInteger idx = [self.theCourse.assignments indexOfObject:self.selectedAssignment];
//	if (idx != NSNotFound)
//		self.theCourse.assignments = [self.theCourse.assignments arrayByRemovingObjectAtIndex:idx];
//	[self.assignments removeObject:self.selectedAssignment];
//	self.selectedAssignment=nil;
//	[self.assignTable reloadData];
//	[self.fileTable reloadData];
}

-(IBAction)uploadFiles:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:RC2_AcceptableImportFileSuffixes()];
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
//	NSString *errorMessage=nil;
//	ASIHTTPRequest *req = [RC2_SharedInstance() requestWithRelativeURL:[NSString stringWithFormat:@"assignment/%@/file/%@", self.selectedAssignment.assignmentId, self.selectedFile.assignmentFileId]];
//	[req setRequestMethod:@"DELETE"];
//	[req startSynchronous];
//	if (req.responseStatusCode != 200) {
//		errorMessage = @"server error deleting file";
//	} else {
//		NSDictionary *d = [req.responseString JSONValue];
//		if ([[d objectForKey:@"status"] intValue] != 0) {
//			errorMessage = [d objectForKey:@"message"];
//		} else {
//			[self.selectedAssignment updateWithDictionary:[d objectForKey:@"assignment"]];
//			[self.fileTable reloadData];
//		}
//	}
}

-(IBAction)showStudents:(id)sender
{
//	ASIHTTPRequest *req = [RC2_SharedInstance() requestWithRelativeURL:[NSString stringWithFormat:@"assignment/%@/due", self.selectedAssignment.assignmentId]];
//	[req startSynchronous];
//	if (req.responseStatusCode == 200) {
//		NSDictionary *d = [req.responseString JSONValue];
//		[self.students removeAllObjects];
//		for (NSDictionary *sdict in [d objectForKey:@"students"]) {
//			NSMutableDictionary *md = [sdict mutableCopy];
//			[md setObject:[NSDate dateWithTimeIntervalSince1970:[[md objectForKey:@"duedate"] longValue] / 1000] forKey:@"duedate"];
//			[self.students addObject:md];
//		}
//		[self.studentTable reloadData];
//	}
}

#pragma mark - meat & potatos

-(void)resortAssignments
{
	[self.assignments sortUsingDescriptors:self.assignSortDescriptors];
}

//resets status/busy when finished
-(void)importFiles:(NSArray*)fileUrls
{
//	NSString *errorMessage=nil;
//	NSString *uploadUrl = [NSString stringWithFormat:@"assignment/%@/file", self.selectedAssignment.assignmentId];
//	for (NSURL *fileUrl in fileUrls) {
//		ASIFormDataRequest *req = [RC2_SharedInstance() postRequestWithRelativeURL:uploadUrl];
//		[req setFile:fileUrl.path forKey:@"content"];
//		[req setPostValue:fileUrl.path.lastPathComponent forKey:@"name"];
//		[req startSynchronous];
//		if (req.responseStatusCode != 200) {
//			errorMessage = @"server error uploading file";
//			break;
//		}
//		NSDictionary *dict = [req.responseString JSONValue];
//		if ([[dict objectForKey:@"status"] intValue] != 0) {
//			errorMessage = [dict objectForKey:@"message"];
//			break;
//		}
//		[self.selectedAssignment updateWithDictionary:[dict objectForKey:@"assignment"]];
//		[self.fileTable reloadData];
//	}
//	if (errorMessage)
//		[NSAlert displayAlertWithTitle:@"Unknown Error" details:errorMessage];
//	//when finished
//	dispatch_async(dispatch_get_main_queue(), ^{
//		self.busy=NO;
//		self.statusMessage=@"";
//	});
}

-(void)loadAssignments
{
//	ASIHTTPRequest *theReq = [RC2_SharedInstance() requestWithRelativeURL:
//							  [NSString stringWithFormat:@"courses/%@", self.theCourse.classId]];
//	__unsafe_unretained ASIHTTPRequest *req = theReq;
//	[theReq setCompletionBlock:^{
//		NSDictionary *rsp = [req.responseString JSONValue];
//		if ([[rsp objectForKey:@"status"] intValue] == 0) {
//			self.theCourse.assignments = [RCAssignment assignmentsFromJSONArray:[rsp objectForKey:@"assignments"] forCourse:self.theCourse];
//			self.assignments = [self.theCourse.assignments mutableCopy];
//			[self.assignTable reloadData];
//		}
//	}];
//	[req startAsynchronous];
}

//TODO: this code is not called. need to adjust importFiles above so that duplicates are handled properly
//-(void)handleFileUpload:(NSArray*)urls replacing:(BOOL)replaceExisting
//{
//	self.statusMessage = @"Uploading Files";
//	self.busy = YES;
//	NSMutableArray *workingUrls = [NSMutableArray arrayWithCapacity:urls.count];
//	for (NSURL *aUrl in urls) {
//		NSString *fname =aUrl.lastPathComponent;
//		if (nil != [self.selectedAssignment.files firstObjectWithValue:fname forKey:@"name"]) {
//			if (replaceExisting) {
//				//deleting existing
//				continue;
//			} else {
//				fname = [MultiFileImporter uniqueFileName:fname existingFiles:self.selectedAssignment.files];
//			}
//		} else {
//			[workingUrls addObject:aUrl];
//		}
//	}
//	[self importFiles:workingUrls];
//	self.busy = NO;
//	self.statusMessage = @"";
//}

-(void)handleAssignmentEdit:(RCAssignment*)assign forProperty:(NSString*)prop newValue:(id)object
{
//	if ([object isKindOfClass:[NSDate class]]) {
//		object = [NSNumber numberWithDouble:[object timeIntervalSince1970] * 1000];
//	}
//	NSDictionary *mods = [NSDictionary dictionaryWithObject:object forKey:prop];
//	NSString *urlstr = [NSString stringWithFormat:@"courses/%@/assignment/%@", self.theCourse.courseId, assign.assignmentId];
//	ASIFormDataRequest *req = [RC2_SharedInstance() postRequestWithRelativeURL:urlstr];
//	[req setRequestMethod:@"PUT"];
//	[req addRequestHeader:@"Content-Type" value:@"application/json"];
//	[req appendPostData:[[mods JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
//	[req startSynchronous];
//	if (req.responseStatusCode == 200) {
//		NSDictionary *d = [req.responseString JSONValue];
//		if ([[d objectForKey:@"status"] intValue] == 0) {
//			[assign updateWithDictionary:[d objectForKey:@"assignment"]];
//			[self resortAssignments];
//		}
//	}
}

-(void)handleFileEdit:(RCAssignmentFile*)afile forProperty:(NSString*)prop newValue:(id)object
{
//	//send to server
//	NSString *urlstr = [NSString stringWithFormat:@"assignment/%@/file/%@", self.selectedAssignment.assignmentId, afile.assignmentFileId];
//	ASIFormDataRequest *req = [RC2_SharedInstance() postRequestWithRelativeURL:urlstr];
//	[req setRequestMethod:@"PUT"];
//	[req addRequestHeader:@"Content-Type" value:@"application/json"];
//	NSDictionary *d = [NSDictionary dictionaryWithObject:object forKey:@"readonly"];
//	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
//	[req startSynchronous];
//	if (req.responseStatusCode == 200) {
//		d = [req.responseString JSONValue];
//		if ([[d objectForKey:@"status"] intValue] == 0) {
//			afile.readonly = [object boolValue];
//		}
//	}
}

-(void)handleDueDateEdit:(NSMutableDictionary*)studentDict newValue:(id)object
{
//	//send to server
//	NSString *urlstr = [NSString stringWithFormat:@"assignment/%@/due", self.selectedAssignment.assignmentId];
//	ASIFormDataRequest *req = [RC2_SharedInstance() postRequestWithRelativeURL:urlstr];
//	[req setRequestMethod:@"PUT"];
//	[req addRequestHeader:@"Content-Type" value:@"application/json"];
//	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:[object timeIntervalSince1970] * 1000], @"duedate", [studentDict objectForKey:@"wsid"], @"wsid", nil];
//	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
//	[req startSynchronous];
//	if (req.responseStatusCode == 200) {
//		d = [req.responseString JSONValue];
//		if ([[d objectForKey:@"status"] intValue] == 0) {
//			[studentDict setObject:object forKey:@"duedate"];
//		}
//	}
}

#pragma mark - table view

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.fileTable) {
		return self.selectedAssignment.files.count;
	} else if (tableView == self.assignTable) {
		return self.assignments.count;
	} else if (tableView == self.studentTable) {
		return self.students.count;
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
	} else if (tableView == self.assignTable) {
		RCAssignment *assign = [self.assignments objectAtIndex:row];
		id val = [assign valueForKey:tableColumn.identifier];
		return val;
	} else if (tableView == self.studentTable) {
		return [[self.students objectAtIndex:row] objectForKey:tableColumn.identifier];
	}
	return nil;
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == self.assignTable) {
		RCAssignment *assign = [self.assignments objectAtIndex:row];
		if (assign.locked) {
			NSBeep();
			return;
		}
		[self handleAssignmentEdit:assign forProperty:tableColumn.identifier newValue:object];
		return;
	} else if (tableView == self.fileTable) {
		if (![tableColumn.identifier isEqualToString:@"readonly"] || self.selectedAssignment.locked) {
			NSBeep();
			return;
		}
		RCAssignmentFile *afile = [self.selectedAssignment.files objectAtIndex:row];
		[self handleFileEdit:afile forProperty:tableColumn.identifier newValue:object];
	} else if (tableView == self.studentTable) {
		[self handleDueDateEdit:[self.students objectAtIndex:row] newValue:object];
	}
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView == self.fileTable)
		return [MultiFileImporter validateTableViewFileDrop:info];
	return NO;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info existingFiles:self.selectedAssignment.files 
							 completionHandler:^(NSArray *urls, BOOL replaceExisting)
	{
		self.statusMessage = @"Uploading Files";
		self.busy = YES;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self importFiles:urls];
		});
	}];
	
	return YES;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if (notification.object == self.assignTable) {
		self.selectedAssignment = [self.assignments objectAtIndexNoExceptions:self.assignTable.selectedRow];
	} else {
		NSInteger idx = [self.fileTable selectedRow];
		self.selectedFile = [self.selectedAssignment.files objectAtIndexNoExceptions:idx];
	}
}

-(void)setSelectedAssignment:(RCAssignment *)assign
{
	if (assign == _selectedAssignment)
		return;
//	self.curSelToken = [assign addObserverForKeyPath:@"name" task:^(id obj, NSDictionary *change) {
//		NSLog(@"name changed: %@, %@", [obj name], change);
//	}];
	_selectedAssignment = assign;
	self.selectedFile=nil;
	[self.fileTable reloadData];
	[self.students removeAllObjects];
	[self.studentTable reloadData];
}

@end
