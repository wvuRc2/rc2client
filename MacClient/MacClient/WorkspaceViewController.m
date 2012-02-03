//
//  WorkspaceViewController.m
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "WorkspaceViewController.h"
#import "RCWorkspace.h"
#import "RCWorkspaceShare.h"
#import "RCWorkspaceCache.h"
#import "WorkspaceCellView.h"
#import "RCMAddShareController.h"
#import "MacMainWindowController.h"
#import "ASIFormDataRequest.h"
#import "AppDelegate.h"
#import "Rc2Server.h"
#import "RCFile.h"
#import "MultiFileImporter.h"
#import "RCMAppConstants.h"

@interface WorkspaceViewController()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) RCMAddShareController *addController;
@property (nonatomic, strong) NSPopover *addPopover;
@property (nonatomic, assign) BOOL ignoreSectionReloads;
-(void)loadShares;
-(void)handleAddShare:(NSNumber*)userId cellView:(WorkspaceCellView*)wcv;
@end

@implementation WorkspaceViewController

-(id)initWithWorkspace:(RCWorkspace*)aWorkspace
{
	self = [super initWithNibName:@"WorkspaceViewController" bundle:nil];
	if (self) {
		self.workspace = aWorkspace;
		self.kvoTokens = [NSMutableSet set];
		__unsafe_unretained WorkspaceViewController *blockSelf = self;
		[self.kvoTokens addObject:[self.workspace addObserverForKeyPath:@"files" task:^(id obj, NSDictionary *change)
	   {
		   if (!blockSelf.ignoreSectionReloads) {
			   dispatch_async(dispatch_get_main_queue(), ^{
					[blockSelf.sectionsTableView reloadData];
			   });
		   }
	   }]];
		[self.kvoTokens addObject:[self.workspace addObserverForKeyPath:@"shares" task:^(id obj, NSDictionary *change)
		{
			if (!blockSelf.ignoreSectionReloads) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[blockSelf.sectionsTableView reloadData];
				});
			}
		}]];
		[self.workspace refreshShares];
		RCWorkspaceCache *cache = self.workspace.cache;
		NSMutableArray *secs = [NSMutableArray array];
		[secs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Files", @"name", 
						 [NSNumber numberWithBool:[cache boolPropertyForKey:@"WVC_FilesExpanded"]], @"expanded", 
						 @"WVC_FilesExpanded", @"expandedKey", @"files", @"childAttr", nil]];
		if (!aWorkspace.sharedByOther)
			[secs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sharing", @"name",
							 [NSNumber numberWithBool:[cache boolPropertyForKey:@"WVC_SharesExpanded"]], @"expanded", 
							 @"WVC_SharesExpanded", @"expandedKey", @"shares", @"childAttr", nil]];
		self.sections = secs;
	}
	return self;
}

-(void)awakeFromNib
{
	[self.sectionsTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	[self.sectionsTableView reloadData];
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(doRefreshFileList:)) {
		return YES;
	} else if (action == @selector(importFile:)) {
		return YES;
	} else if (action == @selector(exportFile:)) {
		id wcv = [self.sectionsTableView viewAtColumn:0 row:0 makeIfNecessary:NO];
		return [wcv selectedObject] != nil;
	}
	return NO;
}

#pragma mark - actions

-(IBAction)doRefreshFileList:(id)sender
{
}

-(IBAction)exportFile:(id)sender
{
	id wcv = [self.sectionsTableView viewAtColumn:0 row:0 makeIfNecessary:NO];
	RCFile *file = [wcv selectedObject];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:file.name];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		NSError *err=nil;
		if (file.isTextFile) {
			[file.currentContents writeToURL:savePanel.URL atomically:YES encoding:NSUTF8StringEncoding error:&err];
		} else {
			[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:file.fileContentsPath] 
													toURL:savePanel.URL 
													error:&err];
		}
		if (err) {
			//FIXME: report error to user
			Rc2LogWarn(@"error exporting file:%@", err);
		}
	}];
}

-(IBAction)importFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:[Rc2Server acceptableImportFileSuffixes]];
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (NSFileHandlingPanelCancelButton == result)
			return;
		[(AppDelegate*)[TheApp delegate] handleFileImport:[[openPanel URLs] firstObject] 
												  workspace:self.workspace 
										completionHandler:^(RCFile *file)
		{
			if (file) {
				//need to refresh display??
				[self.workspace refreshFiles];
				id wcv = [self tableView:self.sectionsTableView viewForTableColumn:nil row:0];
				[wcv reloadData];
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[NSAlert displayAlertWithTitle:@"Upload failed" details:@"An unknown error occurred."];
				});
			}
		}];
	}];
}

#pragma mark - meat & potatos

-(void)deleteFile:(WorkspaceCellView*)cellView
{
	RCFile *file = cellView.selectedObject;
	[[Rc2Server sharedInstance] deleteFile:file workspace:self.workspace completionHandler:^(BOOL success, id results) {
		if (success) 
			[cellView reloadData];
		else
			[NSAlert displayAlertWithTitle:@"Error" details:@"An unknown error occurred while deleting the selcted file."];
	}];
}

-(void)loadShares
{
}

-(void)handleAddShare:(NSNumber*)userId cellView:(WorkspaceCellView*)wcv
{
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:
							   [NSString stringWithFormat:@"workspace/%@/share", self.workspace.wspaceId]];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[NSString stringWithFormat:@"{\"userid\":%@}", userId]];
	__unsafe_unretained WorkspaceViewController *blockSelf = self;
	req.completionBlock = ^{
		blockSelf.ignoreSectionReloads=YES;
		[blockSelf.workspace refreshShares];
		RunAfterDelay(0.1, ^{
			blockSelf.ignoreSectionReloads=NO;
		});
	};
	[req startAsynchronous];
}

-(void)handleRemoveShare:(RCWorkspaceShare*)share cellView:(WorkspaceCellView*)wcv
{
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:
							   [NSString stringWithFormat:@"workspace/%@/share/%@", self.workspace.wspaceId, share.shareId]];
	req.requestMethod = @"DELETE";
	[req startSynchronous];
	if (req.responseStatusCode == 200) {
		self.ignoreSectionReloads=YES;
		[self.workspace refreshShares];
		RunAfterDelay(0.1, ^{
			self.ignoreSectionReloads=NO;
		});
	}
}
-(void)workspaceCell:(WorkspaceCellView*)cellView addDetail:(id)sender
{
	NSMutableDictionary *secDict = cellView.objectValue;
	if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"shares"]) {
		//handle adding a share
		if (nil == self.addPopover) {
			__unsafe_unretained WorkspaceViewController *blockSelf = self;
			self.addController = [[RCMAddShareController alloc] init];
			self.addController.workspace = self.workspace;
			self.addPopover = [[NSPopover alloc] init];
			self.addPopover.contentViewController = self.addController;
			self.addPopover.behavior = NSPopoverBehaviorTransient;
			self.addController.changeHandler = ^(NSNumber *userId) {
				[blockSelf handleAddShare:userId cellView:cellView];
			};
		}
		[self.addPopover showRelativeToRect:[sender frame] ofView:sender preferredEdge:NSMinYEdge];
	} else if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"files"]) {
		[self importFile:sender];
	}
}

-(void)workspaceCell:(WorkspaceCellView*)cellView removeDetail:(id)sender
{
	NSMutableDictionary *secDict = cellView.objectValue;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"shares"]) {
		//handle removing a share
		RCWorkspaceShare *share = [cellView selectedObject];
		[self handleRemoveShare:share cellView:cellView];
	} else if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"files"]) {
		if ([defaults boolForKey:kPref_SupressDeleteFileWarning]) {
			[self deleteFile:cellView];
		} else {
			RCFile *file = cellView.selectedObject;
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = @"Are you sure you want to delete this file?";
			alert.informativeText = [NSString stringWithFormat:@"The file \"%@\" will be removed from the server. This action can not be undone.", file.name];
			alert.showsSuppressionButton = YES;
			[alert addButtonWithTitle:@"OK"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *theAlert, NSInteger returnCode) {
				if (alert.suppressionButton.state == NSOnState)
					[defaults setBool:YES forKey:kPref_SupressDeleteFileWarning];
				if (returnCode == NSAlertFirstButtonReturn)
					[self deleteFile:cellView];
			}];
		}
	}
}

-(void)workspaceCell:(WorkspaceCellView*)cellView doubleClick:(id)sender
{
	RCFile *file = cellView.selectedObject;
	if (!file.isTextFile) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:file];
		
	} else {
		MacMainWindowController *mainwc = [NSApp valueForKeyPath:@"delegate.mainWindowController"];
		[mainwc openSession:self.workspace file:file inNewWindow:NO];
	}
}

-(void)workspaceCell:(WorkspaceCellView *)cellView setExpanded:(BOOL)expanded
{
	NSString *cacheKey = [cellView.objectValue objectForKey:@"expandedKey"];
	[self.workspace.cache setBoolProperty:expanded forKey:cacheKey];
}

-(void)workspaceCell:(WorkspaceCellView *)cellView handleDroppedFiles:(NSArray*)files replaceExisting:(BOOL)replace
{
	MultiFileImporter *mfi = [[MultiFileImporter alloc] init];
	mfi.workspace = self.workspace;
	mfi.replaceExisting = replace;
	mfi.fileUrls = files;
	AMProgressWindowController *pwc = [mfi prepareProgressWindowWithErrorHandler:^(MultiFileImporter *mfiRef) {
		[self presentError:mfiRef.lastError modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
	}];
	[[NSOperationQueue mainQueue] addOperation:mfi];
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSApp beginSheet:pwc.window modalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	});
}

#pragma mark - table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.sections count];
}
-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *ident = row == 0 ? @"filecell" : @"sharecell";
	WorkspaceCellView *view = [tableView makeViewWithIdentifier:ident owner:nil];
	view.parentTableView = tableView;
	view.objectValue = [self.sections objectAtIndex:row];
	view.expanded = [[view.objectValue valueForKey:@"expanded"] boolValue];
	view.acceptsFileDragAndDrop = [[view.objectValue valueForKey:@"childAttr"] isEqualToString:@"files"];
	view.workspace = self.workspace;
	view.cellDelegate = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
	});
	return view;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSDictionary *d = [self.sections objectAtIndex:row];
	WorkspaceCellView *view = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
	CGFloat h = [[d objectForKey:@"expanded"] boolValue] ? [view expandedHeight] : 27;
	if (0 == h)
		h = 27;
	return h;
}

@synthesize workspace;
@synthesize sectionsTableView;
@synthesize kvoTokens;
@synthesize sections;
@synthesize addPopover;
@synthesize addController;
@synthesize ignoreSectionReloads;
@synthesize selectedFile;
@end
