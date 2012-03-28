//
//  RCMToolbarView.m
//  MacClient
//
//  Created by Mark Lilback on 3/28/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCMToolbarView.h"

@implementation RCMToolbarView

-(void)drawRect:(NSRect)dirtyRect
{
	NSRect r = self.bounds;
	NSRect bgRect = dirtyRect;
	bgRect.origin.x -= 2;
	bgRect.size.width += 4;
//	bgRect.origin.y += 2;
	bgRect.size.height += 2;
//	NSDrawDarkBezel(bgRect, r);	
	NSDrawGrayBezel(bgRect, r);	
	r = dirtyRect;
	r.size.height = 2;
	[[NSColor colorWithHexString:@"777777"] set];
	NSRectFill(r);
}

@end
