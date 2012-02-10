//
//  MacClientAbstractViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacClientAbstractViewController.h"

@implementation MacClientAbstractViewController
@synthesize busy;
@synthesize statusMessage=_statusMessage;

-(void)setStatusMessage:(NSString *)statusMessage
{
	_statusMessage = [statusMessage copy];
	if (statusMessage) {
		RunAfterDelay(5, ^{
			if ([statusMessage isEqualToString:_statusMessage] && !self.busy)
				self.statusMessage=nil;
		});
	}
}

-(NSView*)rightStatusView
{
	return nil;
}
@end
