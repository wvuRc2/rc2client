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

@interface LoginController() <UIViewControllerAnimatedTransitioning>
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
	[self.view setNeedsUpdateConstraints];
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

#pragma mark - view transition

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	self.presenting = YES;
	return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	self.presenting = NO;
	return self;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
	UIView *container = [transitionContext containerView];
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	
	BOOL landscape = UIInterfaceOrientationIsLandscape(fromController.interfaceOrientation);
	CGSize parentSize = container.frame.size;

	if (nil == self.xConstraint) {
		CGFloat startY = (landscape ? parentSize.width : parentSize.height);
		CGFloat startX = fabs((landscape ? parentSize.height - kViewHeight : parentSize.width - kViewWidth)/2.0);
		self.xConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeLeft multiplier:1 constant:startX];
		self.yConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeTop multiplier:1 constant:startY];
		NSLog(@"startx=%1f, starty=%1f", startX, startY);
	}
	
	CGFloat targetY = 200;
	container.autoresizesSubviews = NO;
	if (self.presenting) {
		[container addSubview:self.view];
		[container addConstraint:self.xConstraint];
		[container addConstraint:self.yConstraint];
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kViewWidth]];
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kViewHeight]];
		CGFloat lmargin = fabs((landscape ? parentSize.height - kViewHeight : parentSize.width - kViewWidth)/2.0);
		targetY = 200;
		if (landscape) {
			targetY = lmargin;
		}
	} else {
		targetY = parentSize.height;
	}
	[self.view layoutIfNeeded];
	[CATransaction flush];
	NSLog(@"frame=%@", NSStringFromCGRect(self.view.frame));
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSLog(@"x=%1f, y=%1f", self.xConstraint.constant, self.yConstraint.constant);
		[UIView animateWithDuration:3 animations:^{
			self.yConstraint.constant = targetY;
			[self.view setNeedsLayout];
		} completion:^(BOOL finished) {
			NSLog(@"x=%1f, y=%1f, fin=%d", self.xConstraint.constant, self.yConstraint.constant, finished);
			if (!self.presenting)
				[self.view removeFromSuperview];
			[transitionContext completeTransition:YES];
			NSLog(@"frame=%@", NSStringFromCGRect(self.view.frame));
		}];
	});
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return kAnimDuration;
}

@end
