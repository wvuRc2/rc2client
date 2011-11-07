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
#import "RCMAddShareController.h"
#import "ASIFormDataRequest.h"
#import "Rc2Server.h"

@interface WorkspaceViewController()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) RCMAddShareController *addController;
@property (nonatomic, strong) NSPopover *addPopover;
-(void)loadShares;
-(void)handleAddDetailItem:(WorkspaceCellView*)cellView sender:(id)sender;
-(void)handleRemoveDetailItem:(WorkspaceCellView*)cellView sender:(id)sender;
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

-(void)loadShares
{
}

-(void)handleAddShare:(NSNumber*)userId cellView:(WorkspaceCellView*)wcv
{
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:
							   [NSString stringWithFormat:@"fd/wspace/share/%@", self.workspace.wspaceId]];
	[req setPostValue:userId forKey:@"userid"];
	__unsafe_unretained WorkspaceViewController *blockSelf = self;
	req.completionBlock = ^{
		[blockSelf.workspace refreshShares];
	};
	[req startAsynchronous];
}

-(void)handleAddDetailItem:(WorkspaceCellView*)cellView sender:(id)sender
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
	}
}

-(void)handleRemoveDetailItem:(WorkspaceCellView*)cellView sender:(id)sender
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
	view.addDetailHander = ^(id cell, id sender) {
		[self handleAddDetailItem:cell sender:sender];
	};
	view.removeDetailHander = ^(id cell, id sender) {
		[self handleRemoveDetailItem:cell sender:sender];
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
@end
