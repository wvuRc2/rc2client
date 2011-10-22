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
@end

@implementation WorkspaceCellView
@synthesize expanded=__expanded;
@synthesize parentTableView=__parentTableView;
-(void)awakeFromNib
{
	[self setWantsLayer:YES];
	self.layer.cornerRadius = 6.0;
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
	
}

-(IBAction)removeDetailItem:(id)sender
{
	
}

#pragma mark - detail table

-(NSArray*)contentArray
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

@synthesize detailTableView;
@synthesize detailItemSelected;
@synthesize workspace;
@end
