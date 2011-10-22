//
//  WorkspaceViewController.m
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "WorkspaceViewController.h"
#import "RCWorkspace.h"
#import "WorkspaceCellView.h"

@interface WorkspaceViewController()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, copy) NSArray *sections;
-(void)handleAddDetailItem:(WorkspaceCellView*)cellView;
-(void)handleRemoveDetailItem:(WorkspaceCellView*)cellView;
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
			[blockSelf.sectionsTableView reloadData];
	   }]];
		[self.kvoTokens addObject:[self.workspace addObserverForKeyPath:@"shares" task:^(id obj, NSDictionary *change)
		{
			[blockSelf.sectionsTableView reloadData];
		}]];
		[self.workspace refreshShares];
		NSMutableArray *secs = [NSMutableArray array];
		[secs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Files", @"name", 
							   [NSNumber numberWithBool:NO], @"expanded", 
							   @"files", @"childAttr", nil]];
		if (!aWorkspace.sharedByOther)
			[secs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sharing", @"name",
							   [NSNumber numberWithBool:NO], @"expanded", @"shares", @"childAttr", nil]];
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
	}
	return NO;
}

#pragma mark - actions

-(IBAction)doRefreshFileList:(id)sender
{

}

#pragma mark - meat & potatos

-(void)handleAddDetailItem:(WorkspaceCellView*)cellView
{
	NSMutableDictionary *secDict = cellView.objectValue;
	if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"shares"]) {
		//handle adding a share
	}
}

-(void)handleRemoveDetailItem:(WorkspaceCellView*)cellView
{
	NSMutableDictionary *secDict = cellView.objectValue;
	if ([[secDict objectForKey:@"childAttr"] isEqualToString:@"shares"]) {
		//handle removing a share
	}
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
	view.workspace = self.workspace;
	view.addDetailHander = ^(id cell) {
		[self handleAddDetailItem:cell];
	};
	view.removeDetailHander = ^(id cell) {
		[self handleRemoveDetailItem:cell];
	};
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
	return h;
}

@synthesize workspace;
@synthesize sectionsTableView;
@synthesize kvoTokens;
@synthesize sections;
@end
