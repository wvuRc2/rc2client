//
//  ProjectViewTransition.m
//  Rc2Client
//
//  Created by Mark Lilback on 8/20/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ProjectViewTransition.h"
#import "ProjectViewController.h"
#import "WorkspaceViewController.h"

@interface ProjectViewTransition ()
@property (nonatomic, weak) AbstractProjectViewController *srcVC;
@property (nonatomic, weak) AbstractProjectViewController *destVC;
@end

const CGFloat ANIM_DURATION = 0.4;

@implementation ProjectViewTransition
-(id)initWithFromController:(AbstractProjectViewController*)fromVC toController:(AbstractProjectViewController*)toVC
{
	if ((self = [super init])) {
		self.srcVC = fromVC;
		self.destVC = toVC;
	}
	return self;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	self.srcVC.view.alpha = 1;
	self.destVC.view.alpha = 0.05;
	UIView *container = [transitionContext containerView];
	container.backgroundColor = [UIColor clearColor];
	self.destVC.view.backgroundColor = [UIColor clearColor];
	[container addSubview:self.srcVC.view];
	[container insertSubview:self.destVC.view aboveSubview:self.srcVC.view];
	[container removeConstraints:container.constraints];
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views: @{@"view":self.srcVC.view}]];
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[view]-(0)-|" options:0 metrics:nil views: @{@"view":self.srcVC.view}]];
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views: @{@"view":self.destVC.view}]];
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[view]-(0)-|" options:0 metrics:nil views: @{@"view":self.destVC.view}]];
	[UIView animateWithDuration:ANIM_DURATION delay:0 options:0 animations:^{
		self.srcVC.view.alpha = 0.1;
		self.destVC.view.alpha = 1;
	} completion:^(BOOL finished) {
		[self.srcVC.view removeFromSuperview];
		[transitionContext completeTransition:YES];
	}];
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return ANIM_DURATION;
}
@end
