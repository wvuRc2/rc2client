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

#define ANIM_DURATION 0.4

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
	self.destVC.view.alpha = 0;
	[[transitionContext containerView] addSubview:self.destVC.view];
/*	if ([self.destVC isKindOfClass:[WorkspaceViewController class]]) {
		CABasicAnimation *fan = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fan.duration = ANIM_DURATION;
		fan.toValue = @0;
		[self.srcVC.view.layer addAnimation:fan forKey:nil];
		CGRect srcFrame = self.srcVC.clickedCellFrame;
		fan = [CABasicAnimation animationWithKeyPath:@"frame"];
		fan.fromValue = [NSValue valueWithCGRect:srcFrame];
		fan.toValue = [NSValue valueWithCGRect:self.srcVC.view.frame];
		fan.duration = ANIM_DURATION;
		[self.destVC.view.layer addAnimation:fan forKey:nil];

		self.srcVC.view.alpha = 0;
		[self.destVC.view removeConstraints:self.destVC.view.constraints];
		self.destVC.view.frame = srcFrame;
		[UIView animateWithDuration:ANIM_DURATION animations:^{
			self.destVC.view.frame = self.srcVC.view.frame;
		} completion:^(BOOL finished){
			[transitionContext completeTransition:finished];
		}];
	} else {
*/		//for transition back to project view we'll just cross-fade
		[UIView animateWithDuration:ANIM_DURATION delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
			self.srcVC.view.alpha = 0;
			self.destVC.view.alpha = 1;
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:YES];
		}];
//	}
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return ANIM_DURATION;
}
@end
