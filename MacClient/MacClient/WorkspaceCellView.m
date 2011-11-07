//
//  WorkspaceCellView.m
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "WorkspaceCellView.h"
#import "RCWorkspace.h"

@interface WorkspaceCellView()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@end

@implementation WorkspaceCellView
@synthesize expanded=__expanded;
@synthesize parentTableView=__parentTableView;
@synthesize workspace=__workspace;

-(void)awakeFromNib
{
	self.kvoTokens = [NSMutableSet set];
	[self setWantsLayer:YES];
	self.layer.cornerRadius = 6.0;
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
	self.addDetailHander(self, sender);
}

-(IBAction)removeDetailItem:(id)sender
{
	self.removeDetailHander(self, sender);
}

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
}

-(void)setWorkspace:(RCWorkspace *)workspace
{
	ZAssert(self.objectValue, @"no objectvalue set yet");
	__workspace = workspace;
	[self.kvoTokens addObject:[workspace addObserverForKeyPath:[self.objectValue objectForKey:@"childAttr"] 
														  task:^(id obj, NSDictionary *change) 
	{
		[self.detailTableView reloadData];
	}]];
}

@synthesize detailTableView;
@synthesize detailItemSelected;
@synthesize addDetailHander;
@synthesize removeDetailHander;
@synthesize kvoTokens;
@end
