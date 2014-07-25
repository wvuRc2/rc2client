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
@property BOOL presenting;
@end

static const CGFloat kAnimDuration = 0.4;

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
	
	CGAffineTransform completeTransform = CGAffineTransformIdentity;

	container.autoresizesSubviews = NO;
	if (self.presenting) {
		[container addSubview:self.view];
		[container addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
		[container addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeTop multiplier:1 constant:200]];
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:342]];
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:301]];
		self.view.transform = CGAffineTransformMakeTranslation(0, container.bounds.size.height);
	} else {
		completeTransform = CGAffineTransformMakeTranslation(0, container.bounds.size.height);
	}
	
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.view.transform = completeTransform;
	} completion:^(BOOL finished) {
		if (!self.presenting)
			[self.view removeFromSuperview];
		[transitionContext completeTransition:YES];
	}];
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
	return kAnimDuration;
}

@end
