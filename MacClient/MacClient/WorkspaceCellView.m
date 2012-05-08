//
//  WorkspaceCellView.m
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "WorkspaceCellView.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "Rc2Server.h"
#import "MultiFileImporter.h"

@interface RCFile(MacSupport)
-(id)permissionImage;
@end

@implementation RCFile(MacSupport)
-(id)permissionImage
{
	if ([self readOnlyValue]) return [NSImage imageNamed:NSImageNameLockLockedTemplate];
	return nil;
}
@end

@interface WorkspaceCellView()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, retain, readwrite) id selectedObject;
@end

@implementation WorkspaceCellView
@synthesize expanded=__expanded;
@synthesize parentTableView=__parentTableView;
@synthesize workspace=__workspace;
@synthesize acceptsFileDragAndDrop=__acceptsFileDragAndDrop;
@synthesize selectedObject;

-(void)awakeFromNib
{
	self.kvoTokens = [NSMutableSet set];
	[self setWantsLayer:YES];
	self.layer.cornerRadius = 6.0;
	self.detailTableView.target = self;
	[self.detailTableView setDoubleAction:@selector(doubleClick:)];
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[super resizeSubviewsWithOldSize:oldSize];
	NSScrollView *sv = [self.detailTableView enclosingScrollView];
	NSRect r = sv.frame;
	r.size.height = self.frame.size.height - 48;
	sv.frame = r;
}

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect masterRect = NSInsetRect(dirtyRect, 4, 1);
	NSRect dr = masterRect;
	dr.origin.y = NSMaxY(dr) - 25;
	dr.size.height = 25;
	NSString *rightImgName = !self.expanded ? @"accord-rightExpanded" : @"accord-right";
	NSDrawThreePartImage(dr, [NSImage imageNamed:@"accord-left"], [NSImage imageNamed:@"accord-center"], 
						 [NSImage imageNamed:rightImgName], NO, NSCompositeSourceOver, 1.0, NO);
	if (dirtyRect.size.height > 100) {
		//draw the bottom
		dr = masterRect;
		dr.size.height = 25;
		NSDrawThreePartImage(dr, [NSImage imageNamed:@"baccord-left"], [NSImage imageNamed:@"baccord-center"], 
							 [NSImage imageNamed:@"baccord-right"], NO, NSCompositeSourceOver, 1.0, NO);
	}
}

#pragma mark - actions

-(IBAction)addDetailItem:(id)sender
{
	[self.cellDelegate workspaceCell:self addDetail:sender];
}

-(IBAction)removeDetailItem:(id)sender
{
	[self.cellDelegate workspaceCell:self removeDetail:sender];
}

-(IBAction)doubleClick:(id)sender
{
	[self.cellDelegate workspaceCell:self doubleClick:sender];
}

-(void)reloadData
{
	[self.detailTableView reloadData];
}

#pragma mark - files

#pragma mark - detail table

-(NSMutableArray*)contentArray
{
	return [self.workspace valueForKey:[self.objectValue objectForKey:@"childAttr"]];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.contentArray count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id obj = [self.contentArray objectAtIndex:row];
	return [obj valueForKey:[tableColumn identifier]];
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object 
  forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id obj = [self.contentArray objectAtIndex:row];
	[obj setValue:object forKey:[tableColumn identifier]];
}

-(void)tableViewSelectionDidChange:(NSNotification *)note
{
	id oval = [self.contentArray objectAtIndexNoExceptions:[self.detailTableView selectedRow]];
	self.detailItemSelected = oval != nil;
	self.selectedObject = oval;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	//only support dragging of files
	if (!self.acceptsFileDragAndDrop)
		return NO;
	NSArray *objs = [self.contentArray objectsAtIndexes:rowIndexes];
	NSMutableArray *pitems = [NSMutableArray arrayWithCapacity:objs.count];
	for (RCFile *file in objs) {
		[pitems addObject:[NSURL fileURLWithPath:file.fileContentsPath]];
	}
	[pboard writeObjects:pitems];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	return [MultiFileImporter validateTableViewFileDrop:info];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info existingFiles:self.workspace.files 
							 completionHandler:^(NSArray *urls, BOOL replaceExisting)
	 {
		 [self.cellDelegate workspaceCell:self handleDroppedFiles:urls replaceExisting:replaceExisting];
	 }];
	return YES;
}

#pragma mark - accessors

-(CGFloat)expandedHeight
{
	//figure out # of rows (min 3) and then add 48 for the surrounding chrome
	return 48 + (19 * fmaxf(3,[self.contentArray count]+1));
}

-(void)setParentTableView:(NSTableView *)parentTableView
{
	__parentTableView = parentTableView;
	[self.parentTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[self.parentTableView rowForView:self]]];
}

-(void)setExpanded:(BOOL)expanded
{
	__expanded = expanded;
	[self.objectValue setObject:[NSNumber numberWithBool:expanded] forKey:@"expanded"];
	[self.detailTableView setHidden:!expanded];
	[self.parentTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[self.parentTableView rowForView:self]]];
	[self.cellDelegate workspaceCell:self setExpanded:__expanded];
}

-(void)setWorkspace:(RCWorkspace *)workspace
{
	ZAssert(self.objectValue, @"no objectvalue set yet");
	__workspace = workspace;
	[self.kvoTokens addObject:[workspace addObserverForKeyPath:[self.objectValue objectForKey:@"childAttr"] 
														  task:^(id obj, NSDictionary *change) 
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.detailTableView reloadData];
		});
	}]];
}

-(void)setAcceptsFileDragAndDrop:(BOOL)accept
{
	__acceptsFileDragAndDrop = accept;
	if (accept) {
		[self.detailTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
		[self.detailTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleNone];
		[self.detailTableView registerForDraggedTypes:ARRAY((id)kUTTypeFileURL)];
	}
}

@synthesize detailTableView;
@synthesize detailItemSelected;
@synthesize kvoTokens;
@synthesize cellDelegate;
@end
