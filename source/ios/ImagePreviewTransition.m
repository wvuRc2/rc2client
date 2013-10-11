//
//  ImagePreviewTransition.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ImagePreviewTransition.h"

@implementation ImagePreviewTransition

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIView *container = [transitionContext containerView];
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	if (self.isDismissal) {
//		CGRect imgRect = inController.view.bounds;
//		UIGraphicsBeginImageContext(imgRect.size);
//		[inController.view.layer renderInContext:UIGraphicsGetCurrentContext()];
//		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//		UIGraphicsEndImageContext();
//		UIImageView *iview = [[UIImageView alloc] initWithFrame:imgRect];
//		iview.image = img;
//		[childController.view addSubview:iview];
//		[inController.view removeFromSuperview];
		
		[UIView animateWithDuration:0.5 animations:^{
			self.presented.view.frame = self.srcRect;
//			iview.frame = self.srcRect;
		} completion:^(BOOL finished) {
//			[self.presented removeFromParentViewController];
			[self.presented.view removeFromSuperview];
//			[iview removeFromSuperview];
//			[inController removeFromParentViewController];
			[transitionContext completeTransition:YES];
		}];
	} else {
		UIView *dview = toController.view;
		CGRect startFrame = [self.presenting.view convertRect:self.srcRect toView:container];
		dview.frame = startFrame;
		[container addSubview:dview];
		CGRect endFrame = CGRectMake(0, 0, 400, 450);
		CGSize csz = container.bounds.size;
		if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
			//we want to center on container
			endFrame.origin.x = floorf((csz.width - endFrame.size.width)/2);
			endFrame.origin.y = floorf((csz.height - endFrame.size.height)/2);
			[UIView animateWithDuration:0.5 animations:^{
				dview.frame = endFrame;
			} completion:^(BOOL finished) {
				[transitionContext completeTransition:YES];
			}];
		} else {
			if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
				csz = CGSizeMake(1024, 768);
			endFrame.origin.x = csz.width - endFrame.size.width - 20;
			endFrame.origin.y = csz.height/2;
			[UIView animateWithDuration:0.5 animations:^{
				dview.frame = endFrame;
//				dview.bounds = endFrame;
//				dview.center = CGPointMake((endFrame.size.width-endFrame.size.width -20), csz.height/2);//CGPointMake(csz.width - 20 - (endFrame.size.width/2), floorf(csz.height/2));
			} completion:^(BOOL finished) {
				[transitionContext completeTransition:YES];
			}];
		}

		/*self.presented.view.frame = self.srcRect;
		[self.presenting.view addSubview:self.presented.view];
//		[self.presenting addChildViewController:self.presented];
//		childController.view.frame = self.srcRect;
//		[inController.view addSubview:childController.view];
		[UIView animateWithDuration:0.5 animations:^{
			CGSize sz = self.presenting.view.frame.size;
			self.presented.view.center = CGPointMake(floorf(sz.width/2), floorf(sz.height/2));
			self.presented.view.bounds = CGRectMake(0, 0, 400, 450);
//			childController.view.bounds = CGRectMake(0, 0, 400, 450);
//			childController.view.center = inController.view.center;
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:YES];
		}]; */
	}
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return 0.5;
}

@end
