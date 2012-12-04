//
//  MCSessionFileController.m
//  Rc2Client
//
//  Created by Mark Lilback on 12/4/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCSessionFileController.h"
#import "RCFile.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "Rc2FileType.h"
#import "RCMSessionFileCellView.h"
#import "MultiFileImporter.h"

@interface MCSessionFileController ()
@property (nonatomic, strong) NSArray *fileArray;
@property (nonatomic, weak) RCFile *fileToInitiallySelect;

@end

@implementation MCSessionFileController

-(id)initWithSession:(RCSession*)aSession tableView:(NSTableView*)tableView delegate:(id<MCSessionFileControllerDelegate>)aDelegate
{
	if ((self = [super init])) {
		self.session = aSession;
		self.fileTableView = tableView;
		self.delegate = aDelegate;
		//fire faults on all file objects for efficency
		[self.session.workspace.files valueForKey:@"name"];
		[self updateFileArray];
		__weak MCSessionFileController *blockSelf = self;
		[self storeNotificationToken:[[NSNotificationCenter defaultCenter] addObserverForName:RCWorkspaceFilesFetchedNotification
																					   object:nil queue:nil usingBlock:^(NSNotification *note)
		{
		  dispatch_async(dispatch_get_main_queue(), ^{
			  [blockSelf updateFileArray];
			  if (blockSelf.fileToInitiallySelect) {
				  [blockSelf setSelectedFile:blockSelf.fileToInitiallySelect];
				  blockSelf.fileToInitiallySelect = nil;
			  }
			  if (blockSelf.fileIdJustImported) {
				  NSUInteger idx = [blockSelf.fileArray indexOfObjectWithValue:blockSelf.fileIdJustImported usingSelector:@selector(fileId)];
				  if (NSNotFound != idx) {
					  [blockSelf.fileTableView amSelectRow:idx byExtendingSelection:NO];
				  }
				  blockSelf.fileIdJustImported=nil;
				  [blockSelf tableViewSelectionDidChange:nil];
			  }
		  });
		}]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workspaceFilesChanged:) name:RCWorkspaceFilesFetchedNotification object:self.session.workspace];
		[self.fileTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
		[self.fileTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleNone];
		[self.fileTableView registerForDraggedTypes:ARRAY((id)kUTTypeFileURL)];
	}
	return self;
}

#pragma mark - meat & potatos

-(void)workspaceFilesChanged:(NSNotification*)note
{
	[self updateFileArray];
}

-(void)updateFileArray
{
	NSArray *sortD = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
	NSMutableArray *srcFiles = [NSMutableArray array];
	NSMutableArray *otherFiles = [NSMutableArray array];
	for (RCFile *aFile in self.session.workspace.files) {
		if (aFile.fileType.isSourceFile)
			[srcFiles addObject:aFile];
		else
			[otherFiles addObject:aFile];
	}
	if (srcFiles.count > 0) {
		[srcFiles sortUsingDescriptors:sortD];
		[srcFiles insertObject:@"Source Files" atIndex:0];
	}
	if (otherFiles.count > 0) {
		[otherFiles sortUsingDescriptors:sortD];
		[srcFiles addObject:@"Other Files"];
		[srcFiles addObjectsFromArray:otherFiles];
	}
	self.fileArray = srcFiles;
	[self.fileTableView reloadData];
}

#pragma mark - table view

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.fileArray.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id obj = [self.fileArray objectAtIndexNoExceptions:row];
	if ([obj isKindOfClass:[RCFile class]]) {
		RCMSessionFileCellView *view = [tableView makeViewWithIdentifier:@"file" owner:nil];
		view.objectValue = obj;
		__unsafe_unretained MCSessionFileController *blockSelf = self;
		view.syncFileBlock = ^(RCFile *theFile) {
			[blockSelf.delegate syncFile:theFile];
		};
		return view;
	}
	NSTableCellView *tview = [tableView makeViewWithIdentifier:@"string" owner:nil];
	tview.textField.stringValue = obj;
	return tview;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	if (aTableView != self.fileTableView)
		return NO;
	RCFile *file = [self.fileArray objectAtIndex:rowIndexes.firstIndex];
	if (![file isKindOfClass:[RCFile class]]) //don't allow dragging of section titles
		return NO;
	NSArray *pitems = ARRAY([NSURL fileURLWithPath:file.fileContentsPath]);
	[pboard writeObjects:pitems];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView != self.fileTableView)
		return NO;
	return [MultiFileImporter validateTableViewFileDrop:info];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info existingFiles:self.fileArray
							 completionHandler:^(NSArray *urls, BOOL replaceExisting)
	 {
		 MultiFileImporter *mfi = [[MultiFileImporter alloc] init];
		 mfi.workspace = self.session.workspace;
		 mfi.replaceExisting = replaceExisting;
		 mfi.fileUrls = urls;
		 AMProgressWindowController *pwc = [mfi prepareProgressWindowWithErrorHandler:^(MultiFileImporter *mfiRef) {
			 [self.fileTableView.window.firstResponder presentError:mfiRef.lastError modalForWindow:self.fileTableView.window delegate:nil didPresentSelector:nil contextInfo:nil];
		 }];
		 [[NSOperationQueue mainQueue] addOperation:mfi];
		 dispatch_async(dispatch_get_main_queue(), ^{
			 [NSApp beginSheet:pwc.window modalForWindow:self.fileTableView.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
		 });
	 }];
	return YES;
}


-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	RCFile *file = [self.fileArray objectAtIndexNoExceptions:[self.fileTableView selectedRow]];
	[self privateSetSelectedFile:file];
}

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	return [[self.fileArray objectAtIndex:row] isKindOfClass:[NSString class]];
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return [[self.fileArray objectAtIndex:row] isKindOfClass:[RCFile class]];
}


#pragma mark - accessors

-(void)setFileTableView:(NSTableView *)fileTableView
{
	_fileTableView = fileTableView;
	fileTableView.delegate = self;
	fileTableView.dataSource = self;
}

-(void)privateSetSelectedFile:(RCFile *)selectedFile
{
	RCFile *oldFile = _selectedFile;
	_selectedFile = selectedFile;
	[self.delegate fileSelectionChanged:selectedFile oldSelection:oldFile];
}


-(void)setSelectedFile:(RCFile *)selectedFile
{
	if (self.session.workspace.isFetchingFiles) {
		self.fileToInitiallySelect = selectedFile;
		return;
	}
	ZAssert([self.fileArray containsObject:selectedFile], @"selecting an unknown file");
	[self privateSetSelectedFile:selectedFile];
	//update the UI
	NSIndexSet *iset = [NSIndexSet indexSetWithIndex:[self.fileArray indexOfObject:selectedFile]];
	[self.fileTableView selectRowIndexes:iset byExtendingSelection:NO];
}

@end
