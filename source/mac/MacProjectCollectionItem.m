//
//  MacProjectCollectionItem.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MacProjectCollectionItem.h"
#import "RCProject.h"

@interface MacProjectCellView : NSView
@property (nonatomic)  BOOL selected;
@property (nonatomic, weak) IBOutlet NSView *innerView;
@end

@implementation MacProjectCollectionItem

-(void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	RCProject *proj = representedObject;
	if ([proj.type isEqualToString:@"shared"])
		self.imageView.image = [NSImage imageNamed:NSImageNameDotMac];
	else if ([proj.type isEqualToString:@"admin"])
		self.imageView.image = [NSImage imageNamed:NSImageNameUserAccounts];
	else
		self.imageView.image = [NSImage imageNamed:NSImageNameFolder];
}

-(void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[(MacProjectCellView*)self.view setSelected:selected];
}

@end

@implementation MacProjectCellView

-(void)awakeFromNib
{
	CALayer *layer = self.innerView.layer;
	layer.cornerRadius = 13.0;
	layer.backgroundColor = [NSColor whiteColor].CGColor;

	layer = [CALayer layer];
	layer.frame = self.innerView.frame;
	layer.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.5].CGColor;
	layer.shadowOpacity = 0.8;
	layer.shadowOffset = CGSizeMake(4, -4);
	layer.shadowRadius = 2;
	layer.cornerRadius = 13.0;
	layer.backgroundColor = [[NSColor blueColor] colorWithAlphaComponent:0.2].CGColor;
	[self.layer addSublayer:layer];
	
	self.layer.backgroundColor = [NSColor clearColor].CGColor;
}

-(void)setSelected:(BOOL)selected
{
	_selected = selected;
	if (selected)
		self.layer.backgroundColor = [NSColor selectedControlColor].CGColor;
	else
		self.layer.backgroundColor = [NSColor whiteColor].CGColor;
	[self.layer setNeedsDisplay];
}

@end