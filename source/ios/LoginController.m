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
@property (nonatomic, strong) NSLayoutConstraint *xConstraint;
@property (nonatomic, strong) NSLayoutConstraint *yConstraint;
@property BOOL presenting;
@end

static const CGFloat kAnimDuration = 0.8;
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
	CGRect rect = [self rectForPresentedState:self.interfaceOrientation containerSize:self.view.superview.bounds.size];
	self.xConstraint.constant = rect.origin.x;
	self.yConstraint.constant = rect.origin.y;
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

-(CGRect)rectForPresentedState:(UIInterfaceOrientation)orientation containerSize:(CGSize)winSize
{
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewHeight, kViewWidth);
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationPortraitUpsideDown:
		case UIInterfaceOrientationUnknown:
			return CGRectMake(fabs((winSize.width - kViewWidth)/2), 200, kViewWidth, kViewHeight);
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


-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIView *container = [transitionContext containerView];
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	LoginController *loginController = (LoginController*)(self.presenting ? toController : fromController);
	UIView *loginView = loginController.view;
	
	BOOL landscape = UIInterfaceOrientationIsLandscape(fromController.interfaceOrientation);
	CGSize parentSize = container.frame.size;

	if (self.presenting && nil == loginController.xConstraint) {
		CGFloat startY = (landscape ? parentSize.width : parentSize.height);
		CGFloat startX = fabs((landscape ? parentSize.height - kViewHeight : parentSize.width - kViewWidth)/2.0);
		loginController.xConstraint = [NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeLeft multiplier:1 constant:startX];
		loginController.yConstraint = [NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeTop multiplier:1 constant:startY];
	}
	
	container.autoresizesSubviews = NO;
	if (self.presenting) {
		[container addSubview:loginView];
		[container addConstraint:loginController.xConstraint];
		[container addConstraint:loginController.yConstraint];
		[toController.view addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kViewWidth]];
		[toController.view addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kViewHeight]];
	} else {
		[container addSubview:fromController.view];
	}
	[UIView animateWithDuration:5 animations:^{
		UIViewController *srcController = self.presenting ? fromController : toController;
		CGRect rect = [loginController rectForPresentedState:srcController.interfaceOrientation containerSize:container.bounds.size];
		loginController.xConstraint.constant = rect.origin.x;
		loginController.yConstraint.constant = rect.origin.y;
		[loginView setNeedsLayout];
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:YES];
	}];
}

@end
