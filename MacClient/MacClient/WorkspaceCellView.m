//
//  WorkspaceCellView.m
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "WorkspaceCellView.h"

@interface WorkspaceCellView()
@property (nonatomic, strong) NSColor *topBorderColor;
@property (nonatomic, strong) NSColor *topTopGradientColor;
@property (nonatomic, strong) NSColor *topBottomGradientColor;
@end

@implementation WorkspaceCellView
@synthesize expanded=__expanded;
@synthesize parentTableView=__parentTableView;
-(void)awakeFromNib
{
	[self setWantsLayer:YES];
	self.layer.cornerRadius = 6.0;
	self.topBorderColor = [NSColor colorWithCalibratedRed:0.600 green:0.600 blue:0.600 alpha:1.000];
	self.topTopGradientColor = [NSColor colorWithCalibratedRed:0.886 green:0.886 blue:0.886 alpha:1.000];
	self.topBottomGradientColor = [NSColor colorWithCalibratedRed:0.784 green:0.784 blue:0.784 alpha:1.000];
}

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect masterRect = NSInsetRect(dirtyRect, 4, 1);
	NSRect borderRect = masterRect;
	NSRect dr = borderRect;
	dr.origin.y = NSMaxY(dr) - 25;
	dr.size.height = 25;
	NSString *rightImgName = !self.expanded ? @"accord-rightExpanded" : @"accord-right";
	NSDrawThreePartImage(dr, [NSImage imageNamed:@"accord-left"], [NSImage imageNamed:@"accord-center"], 
						 [NSImage imageNamed:rightImgName], NO, NSCompositeSourceOver, 1.0, NO);
	if (dirtyRect.size.height > 100) {
		//draw the rest
		dr = masterRect;
		dr.size.height -= 25;
		[[NSColor whiteColor] setFill];
		NSRectFill(dr);
		//draw the bottom
		dr = masterRect;
		dr.size.height = 25;
		NSDrawThreePartImage(dr, [NSImage imageNamed:@"baccord-left"], [NSImage imageNamed:@"baccord-center"], 
							 [NSImage imageNamed:@"baccord-right"], NO, NSCompositeSourceOver, 1.0, NO);
	}
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

@synthesize topBorderColor;
@synthesize topTopGradientColor;
@synthesize topBottomGradientColor;
@synthesize detailTableView;
@end
