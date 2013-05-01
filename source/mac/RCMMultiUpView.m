//
//  RCMMultiUpView.m
//  Rc2Client
//
//  Created by Mark Lilback on 4/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCMMultiUpView.h"

#define kBoxHeightDiff 42

@implementation RCMMultiUpView

- (id)init
{
	if ((self = [super init])) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.wantsLayer = YES;
		self.layer.backgroundColor = [[NSColor blueColor] colorWithAlphaComponent:0.4].CGColor;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)frameDidChange:(NSNotification*)note
{
	[self adjustLayoutBasedOnMode];
	[self setNeedsUpdateConstraints:YES];
}

-(void)setViewControllers:(NSArray *)viewControllers
{
	//remove old views
	for (NSViewController *oldVc in _viewControllers)
		[oldVc.view removeFromSuperview];
	//store new views
	_viewControllers = [viewControllers copy];
	NSArray *views = [_viewControllers valueForKeyPath:@"view"];
	id view1 = views[0];
	//add them as subviews in reverse order
	for (id aView in views.reverseObjectEnumerator) {
		if (![aView conformsToProtocol:@protocol(RCMMultiUpChildView)])
			[NSException raise:NSInvalidArgumentException format:@"proposed view does not conform to RCMMultiUpChildView protocol (%@)", aView];
//		if (![aView isKindOfClass:[NSViewController class]])
//			[NSException raise:NSInvalidArgumentException format:@"proposed viewcontroller is not a viewcontroller (%@)", aView];
		[self addSubview:aView];
		//add constraints for this view
		[aView setMultiXConstraint:[NSLayoutConstraint constraintWithItem:aView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
		[self addConstraint:[aView multiXConstraint]];
		[aView setMultiYConstraint: [NSLayoutConstraint constraintWithItem:aView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
		[self addConstraint:[aView multiYConstraint]];
		
		if (aView == view1) { //first view needs a starting size, will do so at low priority
			[aView setMultiWConstraint: [NSLayoutConstraint constraintWithItem:aView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200]];
			[[aView multiWConstraint] setPriority: 400];
			[self addConstraint:[aView multiWConstraint]];
			[aView setMultiHConstraint:[NSLayoutConstraint constraintWithItem:aView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem: nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200 + kBoxHeightDiff]];
			[[aView multiHConstraint] setPriority:400];
			[self addConstraint:[aView multiHConstraint]];
		}
	}
	//pin size of views to size of first view so all are same size and can just reize first one.
	//doing this outside of previous loop since might need to have set view1's first
	for (NSInteger i=1; i < views.count; i++) {
		id theView = views[i];
		[[theView superview] addConstraint:[NSLayoutConstraint constraintWithItem:theView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
		[[theView superview] addConstraint:[NSLayoutConstraint constraintWithItem:theView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
	}
	
	//now set width & height to be relative to our size
//	[self addConstraint:[NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.46 constant:0]];
//	[self addConstraint:[NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0.46 constant:0]];
}

-(void)layout1up
{
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[context setDuration:0.25];
		[context setAllowsImplicitAnimation:YES];
		for (NSInteger i=0; i < _viewControllers.count; i++) {
			id aView = [_viewControllers[i] view];
			[[[aView multiXConstraint] animator] setConstant:0];
			[[[aView multiYConstraint] animator] setConstant:0];
			if (i == 0) {
				CGFloat height = self.frame.size.height - 40;
				[[[aView multiWConstraint] animator] setConstant:height - kBoxHeightDiff];
				[[[aView multiHConstraint] animator] setConstant:height];
			} else {
				[[aView animator] setAlphaValue:0];
			}
		}
	} completionHandler:^{
	}];
}

-(void)layout2up
{
	CGSize containerSize = self.frame.size;
	CGFloat marginspace = 10 + 10 + 20;
	CGSize newSize = CGSizeMake(fabs((containerSize.width - marginspace)/2), 0);
	CGFloat xAdjust = fabs((newSize.width+20)/2);
	id view1 = [_viewControllers[0] view];
	id view2 = [_viewControllers[1] view];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[context setDuration:self.inLiveResize ? 0 : 0.25];
		[context setAllowsImplicitAnimation:YES];
		[context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[[view2 animator] setAlphaValue: 1.0];
		for (NSInteger i=2; i < _viewControllers.count; i++)
			[[[_viewControllers[i] view] animator] setAlphaValue:0];
		[[[view1 multiWConstraint] animator] setConstant: newSize.width];
		[[[view1 multiHConstraint] animator] setConstant:  newSize.width + kBoxHeightDiff];
		[[[view1 multiXConstraint] animator] setConstant: -xAdjust];
		[[[view2 multiXConstraint] animator] setConstant: xAdjust];
		[[[view1 multiYConstraint] animator] setConstant:0];
		[[[view2 multiYConstraint] animator] setConstant:0];
	} completionHandler:nil];

}

-(void)layout4up
{
	CGSize containerSize = self.frame.size;
	CGFloat marginspace = 10 + 10 + 20;
	CGFloat newWidth =fabs((containerSize.width - marginspace)/2);
	CGFloat newHeight = newWidth + kBoxHeightDiff;
	while ((newHeight*2) + marginspace > containerSize.height) {
		newWidth -=10;
		newHeight -=10;
	}
	CGFloat xAdjust = fabs((containerSize.width-20)/4);
	CGFloat yAdjust = fabs((containerSize.height-20)/4);
	NSArray *views = [_viewControllers valueForKeyPath:@"view"];
	id view1 = views[0];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[context setDuration:self.inLiveResize ? 0 : 0.25];
		[context setAllowsImplicitAnimation:YES];
		[context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		for (NSView *aView in views)
			[aView.animator setAlphaValue:1.0];
		[[[view1 multiWConstraint] animator] setConstant: newWidth];
		[[[view1 multiHConstraint] animator] setConstant:  newWidth + kBoxHeightDiff];
		
		[[[views[0] multiXConstraint] animator] setConstant: -xAdjust];
		[[[views[1] multiXConstraint] animator] setConstant: xAdjust];
		[[[views[2] multiXConstraint] animator] setConstant: -xAdjust];
		[[[views[3] multiXConstraint] animator] setConstant: xAdjust];
		
		[[[views[0] multiYConstraint] animator] setConstant: -yAdjust];
		[[[views[1] multiYConstraint] animator] setConstant: -yAdjust];
		[[[views[2] multiYConstraint] animator] setConstant: yAdjust];
		[[[views[3] multiYConstraint] animator] setConstant: yAdjust];
	} completionHandler:^{
		//		[self.window visualizeConstraints:self.container.constraints];
	}];
}

-(void)adjustLayoutBasedOnMode
{
	switch (_mode) {
		case MultiUpQuantity_1:
			[self layout1up];
			break;
			
		case MultiUpQuantity_2:
			[self layout2up];
			break;
		
		case MultiUpQuantity_4:
			[self layout4up];
			break;
	}	
}

-(void)setMode:(MultiUpMode)mode
{
	_mode = mode;
	[self adjustLayoutBasedOnMode];
}
@end
