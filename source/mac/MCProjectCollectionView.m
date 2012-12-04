//
//  MCProjectCollectionView.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "MCProjectCollectionView.h"

@implementation MCProjectCollectionView

-(IBAction)deleteBackward:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(collectionView:deleteBackwards:)])
		[(id)self.delegate collectionView:self deleteBackwards:sender];
}

-(void)scrollWheel:(NSEvent *)evt
{
	if ([NSEvent isSwipeTrackingFromScrollEventsEnabled]) {
		NSScrollView *sv = [self enclosingScrollView];
		if (sv.documentVisibleRect.origin.x == 0 && evt.deltaX > 0) {
			//they want to go back
			[evt trackSwipeEventWithOptions:NSEventSwipeTrackingLockDirection dampenAmountThresholdMin:0 max:1
							   usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL *stop)
			{
				if (phase == NSEventPhaseEnded && gestureAmount > 0.3) {
					if ([self.delegate respondsToSelector:@selector(collectionView:swipeBackwards:)])
						[(id)self.delegate collectionView:self swipeBackwards:evt];
				}
			 }];
		}
	}
	[super scrollWheel:evt];
}

@end
