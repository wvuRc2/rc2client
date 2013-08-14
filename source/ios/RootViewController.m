//
//  RootViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "RootViewController.h"
#import "WelcomeViewController.h"
#import "MessagesViewController.h"
#import "GradingViewController.h"
#import "ProjectViewController.h"
#import "ThemeEngine.h"

@interface RootViewController () <UIBarPositioningDelegate>
@property (nonatomic, strong) WelcomeViewController *welcomeController;
@property (nonatomic, strong) ProjectViewController *projectController;
@property (nonatomic, strong) MessagesViewController *messageController;
@property (nonatomic, strong) GradingViewController *gradingController;
@property (nonatomic, strong) id currentController;
@end

@interface RootView : UIView
@end

@implementation RootViewController

-(id)init
{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
	}
	return self;
}

-(void)loadView
{
	UIView *view = [[RootView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.view = view;
	self.welcomeController = [[WelcomeViewController alloc] init];
	[self addChildViewController:self.welcomeController];
	[self.welcomeController didMoveToParentViewController:self];
	self.projectController = [[ProjectViewController alloc] init];
	[self addChildViewController:self.projectController];
	[self.projectController didMoveToParentViewController:self];
	[view addSubview:self.projectController.view];
	self.currentController = self.projectController;

	__weak RootViewController *blockSelf = self;
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
		[blockSelf updateForNewTheme:theme];
	}];
	[self updateForNewTheme:[[ThemeEngine sharedInstance] currentTheme]];

}

-(void)updateForNewTheme:(Theme*)theme
{
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}

-(void)viewDidAppear:(BOOL)animated
{
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	UIView* view = self.view;
	NSDictionary *vd = NSDictionaryOfVariableBindings(view);
	[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:vd]];
	[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view]-0-|" options:0 metrics:nil views:vd]];
	[super viewDidAppear:animated];
	self.view.layer.borderWidth = 3;
	self.view.layer.borderColor = [UIColor redColor].CGColor;
	self.welcomeController.view.frame = self.view.bounds;
}

-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;
}

/*
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (self.currentController != self.welcomeController) {
		[self.welcomeController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
}
*/
-(void)showWelcome
{
	[self showWorkspaces];
	[self switchToController:self.welcomeController];
}

-(void)showMessages
{
	if (nil == self.messageController) {
		self.messageController = [[MessagesViewController alloc] init];
		[self addChildViewController:self.messageController];
		[self.messageController didMoveToParentViewController:self];
	}
	[self switchToController:self.messageController];
}

-(void)showWorkspaces
{
	if (nil == self.projectController) {
		self.projectController = [[ProjectViewController alloc] init];
		[self addChildViewController:self.projectController];
		[self.projectController didMoveToParentViewController:self];
		self.projectController.view.frame = self.view.bounds;
	}
	[self switchToController:self.projectController];
}

-(void)showGrading
{
/*	if (nil == self.gradingController) {
		self.gradingController = [[GradingViewController alloc] init];
		[self addChildViewController:self.gradingController];
		[self.gradingController didMoveToParentViewController:self];
		self.gradingController.view.frame = self.view.bounds;
	}
	[self switchToController:self.gradingController]; */
}

-(void)reloadNotifications
{
	[self.welcomeController reloadNotifications];
}

-(void)switchToController:(UIViewController*)vc
{
	if (vc == self.currentController)
		return;
	vc.view.frame = self.view.bounds;
	[self transitionFromViewController:self.currentController 
					  toViewController:vc 
							  duration:0.4 
							   options:UIViewAnimationOptionTransitionCrossDissolve
							animations:^{} 
							completion:^(BOOL finished) {
										self.currentController = vc;
							}];
}

-(void)handleGradingUrl:(NSURL*)url
{
	if (nil == self.gradingController || self.currentController != self.gradingController) {
		[self showGrading];
		RunAfterDelay(0.4, ^{ //same duration as transition animation
			[self.gradingController handleUrl:url];
		});
	} else {
		[self.gradingController handleUrl:url];
	}
}
@end

@implementation RootView

+(BOOL)requiresConstraintBasedLayout { return YES; }

@end

