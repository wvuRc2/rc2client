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

@interface RootViewController ()
@property (nonatomic, strong) WelcomeViewController *welcomeController;
@property (nonatomic, strong) ProjectViewController *projectController;
@property (nonatomic, strong) MessagesViewController *messageController;
@property (nonatomic, strong) GradingViewController *gradingController;
@property (nonatomic, strong) id currentController;
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
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 760)];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view = view;
	self.welcomeController = [[WelcomeViewController alloc] init];
	[self addChildViewController:self.welcomeController];
	[self.welcomeController didMoveToParentViewController:self];
	self.projectController = [[ProjectViewController alloc] init];
	[self addChildViewController:self.projectController];
	[self.projectController didMoveToParentViewController:self];
	[view addSubview:self.projectController.view];
	self.currentController = self.projectController;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.welcomeController.view.frame = self.view.bounds;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (self.currentController != self.welcomeController) {
		[self.welcomeController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)showWelcome
{
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
	if (nil == self.gradingController) {
		self.gradingController = [[GradingViewController alloc] init];
		[self addChildViewController:self.gradingController];
		[self.gradingController didMoveToParentViewController:self];
		self.gradingController.view.frame = self.view.bounds;
	}
	[self switchToController:self.gradingController];
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
