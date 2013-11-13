//
//  RCMTableView.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCMTableView.h"

@implementation RCMTableView

-(void)mouseDown:(NSEvent *)theEvent
{
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger clickedRow = [self rowAtPoint:loc];
	[super mouseDown:theEvent];
	if (clickedRow != -1 && self.varRowClickedBlock)
		self.varRowClickedBlock(clickedRow);
}

@end
