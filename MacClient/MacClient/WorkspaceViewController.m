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
@property (nonatomic, strong) NSArray *sections;
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
			[blockSelf.filesTableView reloadData];
	   }]];
		self.sections = ARRAY([NSMutableDictionary dictionaryWithObjectsAndKeys:@"Files", @"name", 
							   [NSNumber numberWithBool:NO], @"expanded", nil],
							  [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Sharing", @"name",
							   [NSNumber numberWithBool:NO], @"expanded", nil]);
	}
	return self;
}

-(void)awakeFromNib
{
	[self.filesTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
	[self.filesTableView reloadData];
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
	dispatch_async(dispatch_get_main_queue(), ^{
		[tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
	});
	return view;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSDictionary *d = [self.sections objectAtIndex:row];
	CGFloat h = [[d objectForKey:@"expanded"] boolValue] ? 140 : 29;
	NSLog(@"returning %1f for row %ld", h, row);
	return h;
}

@synthesize workspace;
@synthesize filesTableView;
@synthesize kvoTokens;
@synthesize sections;
@end
