//
//  RCMPreviewImageView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/3/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCMPreviewImageView.h"

@implementation RCMPreviewImageView

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

-(void)mouseUp:(NSEvent *)theEvent
{
	NSMenuItem *mi = [self enclosingMenuItem];
	NSMenu *menu = [mi menu];
	[menu cancelTracking];
	[menu performActionForItemAtIndex:[menu indexOfItem:mi]];
}

-(void)setHighlighted:(BOOL)highlighted
{
	if (_highlighted == highlighted)
		return;
	_highlighted = highlighted;
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect
{
	if (_highlighted) {
		[[NSColor selectedMenuItemColor] set];
	} else {
		[[NSColor whiteColor] set];
	}
	NSRectFill(dirtyRect);
}

@end
