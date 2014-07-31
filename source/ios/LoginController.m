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
@property BOOL presenting;
@end

static const CGFloat kAnimDuration = 0.5;
static const CGFloat kViewWidth = 342;
static const CGFloat kViewHeight = 301;

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
	self.hostControl.selectedSegmentIndex = [[Rc2Server sharedInstance] serverHost];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.view.superview.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	CGRect rect = [self finalRectForOrientation:toInterfaceOrientation containerSize:self.view.superview.bounds.size];
	self.view.frame = rect;
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
	[Rc2Server sharedInstance].serverHost = self.hostControl.selectedSegmentIndex;
	__weak LoginController *blockSelf = self;
	[[Rc2Server sharedInstance] loginAsUser:self.useridField.text 
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

-(CGRect)finalRectForOrientation:(UIInterfaceOrientation)orientation containerSize:(CGSize)winSize
{
	BOOL ios7 = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			if (ios7) {
				CGRect r = CGRectMake(100, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationLandscapeRight:
			if (ios7) {
				CGRect r = CGRectMake(winSize.width - 100 -kViewWidth, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationUnknown:
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortraitUpsideDown:
			if (ios7) {
				return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height - 200 - kViewHeight, kViewWidth, kViewHeight);
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
	}
	return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
}


-(CGRect)endRectForPresentedState:(UIInterfaceOrientation)orientation containerSize:(CGSize)winSize
{
	BOOL ios7 = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			if (ios7) {
				CGRect r = CGRectMake(100, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationLandscapeRight:
			if (ios7) {
				CGRect r = CGRectMake(winSize.width - 100 -kViewWidth, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationUnknown:
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortraitUpsideDown:
			if (ios7)
				return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height - 200 - kViewHeight, kViewWidth, kViewHeight);
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
	}
}

-(CGRect)startRectForPresentedState:(UIInterfaceOrientation)orientation containerSize:(CGSize)winSize
{
	BOOL ios7 = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			if (ios7) {
				CGRect r = CGRectMake(winSize.width, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height, kViewWidth, kViewHeight);
		case UIInterfaceOrientationLandscapeRight:
			if (ios7) {
				CGRect r = CGRectMake(0, fabs((winSize.height - kViewWidth)/2), kViewHeight, kViewWidth);
				return r;
			}
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), -kViewHeight, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationUnknown:
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height, kViewWidth, kViewHeight);
		case UIInterfaceOrientationPortraitUpsideDown:
			if (ios7)
				return CGRectMake(fabs((winSize.width - kViewWidth)/2), -kViewHeight, kViewWidth, kViewHeight);
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), winSize.height, kViewWidth, kViewHeight);
	}
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

@end

@implementation LoginTransition

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return kAnimDuration;
}

-(CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation
{
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			return CGAffineTransformMakeRotation(M_PI/-2.0);
		case UIInterfaceOrientationLandscapeRight:
			return CGAffineTransformMakeRotation(M_PI/2.0);
		case UIInterfaceOrientationPortrait:
			return CGAffineTransformIdentity;
		case UIInterfaceOrientationUnknown:
		case UIInterfaceOrientationPortraitUpsideDown:
			return CGAffineTransformMakeRotation(M_PI);
	}
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	BOOL ios7 = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1;
	UIView *container = [transitionContext containerView];
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	LoginController *loginController = (LoginController*)(self.presenting ? toController : fromController);
	UIView *loginView = loginController.view;
	CGSize parentSize = container.bounds.size;

	container.autoresizesSubviews = NO;
	if (self.presenting) {
		[container addSubview:loginView];
	} else {
		[container addSubview:fromController.view];
	}

	UIViewController *srcController = self.presenting ? fromController : toController;
	CGRect containerEnd = [loginController endRectForPresentedState:srcController.interfaceOrientation containerSize:parentSize];
	CGRect containerStart = [loginController startRectForPresentedState:srcController.interfaceOrientation containerSize:parentSize];
	if (!self.presenting) {
		CGRect tmpRect = containerEnd;
		containerEnd = containerStart;
		containerStart = tmpRect;
		if (srcController.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			if (ios7) {
				containerEnd.origin.x = - containerEnd.size.width;
			} else {
				containerEnd.origin.y = parentSize.width;
			}
		}
	} else {
		if (!ios7 && srcController.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			containerStart.origin.y = parentSize.width;
		}
	}
	CGRect viewEnd = [loginController finalRectForOrientation:srcController.interfaceOrientation containerSize:parentSize];

	UIView *snapshotView = [loginController.view snapshotViewAfterScreenUpdates:YES];
	if (ios7)
		snapshotView.transform = [self transformForOrientation:srcController.interfaceOrientation];
	[container addSubview:snapshotView];
	snapshotView.frame = containerStart;
	loginController.view.frame = containerStart;
	loginController.view.hidden = YES;
	[UIView animateWithDuration:kAnimDuration animations:^{
		snapshotView.frame = containerEnd;
		loginView.frame = viewEnd;
	} completion:^(BOOL finished) {
		[snapshotView removeFromSuperview];
		loginView.frame = viewEnd;
		loginView.hidden = NO;
		[transitionContext completeTransition:YES];
	}];
}

@end
