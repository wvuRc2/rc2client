//
//  MCTableRowView.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/3/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "MCTableRowView.h"

@implementation MCTableRowView

//this class solely exists to workaround a autolayout bug with NSTableRowView
// http://stackoverflow.com/questions/14165087/unsatisfiable-constraints-with-nstableview-when-calling-reloaddata


-(void)setFrameSize:(NSSize)newSize
{
	if (!NSEqualSizes(newSize, NSZeroSize))
		[super setFrameSize:newSize];
}

@end
