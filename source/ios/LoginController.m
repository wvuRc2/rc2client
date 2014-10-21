//
//  LoginController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "LoginController.h"
#import "Rc2Server.h"
#import <Vyana-ios/UIAlertView+AMExtensions.h>
#import "Rc2AppConstants.h"
#import "SSKeychain.h"

@interface LoginTransition : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL presenting;
@end

@interface LoginController()
@property (nonatomic) NSLayoutConstraint *topMaginConstraint;
@property BOOL presenting;
@end

@interface LoginPresentationController : UIPresentationController
@property (strong) UIView *dimmingView;
@end

static const CGFloat kAnimDuration = 0.5;
static const CGFloat kViewWidth = 342;
static const CGFloat kViewHeight = 301;
static const CGFloat kVerticalOffset = 100;
static const CGFloat kVerticalOffsetPortrait = 200;

@implementation LoginController

- (id)init
{
	self = [super initWithNibName:@"LoginController" bundle:nil];
	if (self) {
		// Custom initialization
	}
	return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	NSString *lastLogin = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastLogin];
	if (lastLogin) {
		self.useridField.text = lastLogin;
		[self loadPasswordForLogin:lastLogin];
		[self.useridField becomeFirstResponder];
	}
	self.hostControl.selectedSegmentIndex = [RC2_SharedInstance() serverHost];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.view.superview.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	CGRect frame = self.view.window.frame;
	BOOL toWide = frame.size.width < frame.size.height;
	CGRect rect = [self endRectForPresentedState:toWide containerSize:size];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.view.frame = rect;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		
	}];
}

#pragma mark - actions

-(IBAction)doLogin:(id)sender
{
	if (self.useridField.text.length < 2) {
		[UIAlertView showAlertWithTitle:@"Invalid Login" message:@"Logins must be at least 2 characters in length"];
		return;
	}
	self.useridField.enabled = NO;
	self.passwordField.enabled = NO;
	self.loginButton.enabled = NO;
	self.hostControl.enabled = NO;
	[self.busyWheel startAnimating];
	RC2_SharedInstance().serverHost = self.hostControl.selectedSegmentIndex;
	__weak LoginController *blockSelf = self;
	[RC2_SharedInstance() loginAsUser:self.useridField.text 
								   password:self.passwordField.text 
						  completionHandler:^(BOOL success, NSString *message)
	{
		[blockSelf.busyWheel stopAnimating];
		if (success) {
			blockSelf.loginCompleteHandler();
			[blockSelf saveLoginInfo];
		} else {
			[blockSelf reportError:message];
		}
	}];
}

#pragma mark - text delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.useridField)
		[self.passwordField becomeFirstResponder];
	else
		[self doLogin:self];
	return NO;
}

#pragma mark - meat & potatoes

-(void)saveLoginInfo
{
	[SSKeychain setPassword:self.passwordField.text forService:@"Rc2" account:self.useridField.text];
	[[NSUserDefaults standardUserDefaults] setObject:self.useridField.text forKey:kPrefLastLogin];
}

-(void)loadPasswordForLogin:(NSString*)login
{
	NSString *pass = [SSKeychain passwordForService:@"Rc2" account:login];
	if (pass)
		self.passwordField.text = pass;
}

-(void)reportError:(NSString*)errMsg
{
	self.useridField.enabled = YES;
	self.passwordField.enabled = YES;
	self.loginButton.enabled = YES;
	self.hostControl.enabled = YES;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
													message:errMsg
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

-(CGRect)endRectForPresentedState:(BOOL)widescreen containerSize:(CGSize)winSize
{
	CGFloat voffset = widescreen ? kVerticalOffset : kVerticalOffsetPortrait;
	CGRect r = CGRectMake(fabs((winSize.width - kViewWidth)/2), voffset, kViewWidth, kViewHeight);
	return r;
}

-(CGRect)startRectForPresentedState:(BOOL)widescreen containerSize:(CGSize)winSize
{
	return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height, kViewWidth, kViewHeight);
}

#pragma mark - view transition

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	LoginTransition *trans = [[LoginTransition alloc] init];
	trans.presenting = YES;
	return trans;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	LoginTransition *trans = [[LoginTransition alloc] init];
	trans.presenting = NO;
	return trans;
}

- (UIPresentationController*)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
	return [[LoginPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}
@end

@implementation LoginTransition

-(void)setupConstraints:(LoginController*)loginController container:(UIView*)container
{
	UIView *loginView = loginController.view;
	//center x
	[container addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
	//top margin
	loginController.topMaginConstraint = [NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeTopMargin relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeTopMargin multiplier:1.0 constant:100.0];
	[container addConstraint:loginController.topMaginConstraint];
	//width
	[container addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kViewWidth]];
	//height
	[container addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kViewHeight]];
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return kAnimDuration;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIView *container = [transitionContext containerView];
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	LoginController *loginController = (LoginController*)(self.presenting ? toController : fromController);
	UIView *loginView = loginController.view;
	CGSize parentSize = container.bounds.size;
	CGFloat targetMargin = 100;

	container.autoresizesSubviews = NO;
	if (self.presenting) {
		[container addSubview:loginView];
		[self setupConstraints:loginController container:container];
		loginController.topMaginConstraint.constant = parentSize.height;
	} else {
		targetMargin = parentSize.height;
		loginController.topMaginConstraint.constant = 100;
	}
	[loginView layoutIfNeeded];
	loginController.topMaginConstraint.constant = targetMargin;

	[UIView animateWithDuration:kAnimDuration animations:^{
		[container layoutIfNeeded];
	} completion:^(BOOL finished) {
		if (!self.presenting)
			[loginView removeFromSuperview];
		[transitionContext completeTransition:YES];
	}];
}

@end

#pragma mark - PresentationController

@implementation LoginPresentationController

-(instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
	self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
	if (self) {
		self.dimmingView = [[UIView alloc] initWithFrame:presentingViewController.view.bounds];
		self.dimmingView.backgroundColor = [UIColor colorWithWhite:.5 alpha:1];
		self.dimmingView.alpha = 0;
	}
	return self;
}

-(void)presentationTransitionWillBegin
{
	[[self containerView] addSubview:self.dimmingView];
	self.dimmingView.frame = [self containerView].bounds;
	[[self containerView] addSubview:[self presentedViewController].view];
	id <UIViewControllerTransitionCoordinator> transitionCoordinator = [[self presentingViewController] transitionCoordinator];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.dimmingView.alpha = 1.0;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
	}];
}

-(void)dismissalTransitionWillBegin
{
	id <UIViewControllerTransitionCoordinator> transitionCoordinator = [[self presentingViewController] transitionCoordinator];
	[transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		self.dimmingView.alpha = 0.0;
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
	}];
}

-(void)presentationTransitionDidEnd:(BOOL)completed
{
	if (!completed) {
		[self.dimmingView removeFromSuperview];
	}
}
@end
