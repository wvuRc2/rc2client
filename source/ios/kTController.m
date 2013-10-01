//
//  kTController.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "kTController.h"
#import "KTPanel.h"

@interface kTController ()
@property (nonatomic, copy, readwrite) NSArray *panels;
@property (nonatomic, strong, readwrite) UIView *view;
@property (nonatomic, assign) NSUInteger currentPanelIndex;
@end

@implementation kTController

- (id)init
{
	if ((self = [super init])) {
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 3, 1024, 53)];

		NSMutableArray *panels = [NSMutableArray array];
		for (NSString *aNib in @[@"KTExecutePanel", @"KTLatexPanel"]) {
			KTPanel *panel = [[KTPanel alloc] initWithNibName:aNib controller:self];
			[panels addObject:panel];
			[self.view addSubview:panel.view];
			NSLayoutConstraint *xcon = [NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:-1024];
			[self.view addConstraint:xcon];
			panel.xConstraint = xcon;
			[self.view addConstraint:[NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
			[self.view addConstraint:[NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
		}
		self.panels = panels;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

		UIInputView *iview = [[UIInputView alloc] initWithFrame:self.view.frame inputViewStyle:UIInputViewStyleDefault];
		[iview addSubview:self.view];
		self.inputView = iview;

		KTPanel *first = [panels objectAtIndex:0];
		first.xConstraint.constant = 0;
		[self orientationDidChange:nil]; //force initial sizing
}
	return self;
}

-(void)nextPanel:(id)sender
{
	NSUInteger idx = self.currentPanelIndex + 1;
	if (idx >= self.panels.count)
		idx = 0;
	KTPanel *oldPanel = self.panels[self.currentPanelIndex];
	KTPanel *panel = self.panels[idx];
	self.currentPanelIndex = idx;

	
	[UIView performWithoutAnimation:^{
		panel.xConstraint.constant = - self.view.frame.size.width;
		[self.view setNeedsUpdateConstraints];
		[self.view layoutIfNeeded];
		panel.view.hidden = NO;
	}];
	
	[UIView animateWithDuration:0.5 animations:^{
		panel.xConstraint.constant = 0;
		oldPanel.xConstraint.constant = self.view.frame.size.width;
		[self.view setNeedsUpdateConstraints];
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		oldPanel.view.hidden = YES;
	}];
}

-(void)previousPanel:(id)sender
{
	NSInteger idx = self.currentPanelIndex - 1;
	if (idx < 0)
		idx = self.panels.count - 1;
	KTPanel *oldPanel = self.panels[self.currentPanelIndex];
	KTPanel *panel = self.panels[idx];
	self.currentPanelIndex = idx;

	[UIView performWithoutAnimation:^{
		panel.view.hidden = NO;
		panel.xConstraint.constant = self.view.frame.size.width;
		[self.view setNeedsUpdateConstraints];
		[self.view layoutIfNeeded];
	}];
	
	[UIView animateWithDuration:0.5 animations:^{
		panel.xConstraint.constant = 0;
		oldPanel.xConstraint.constant = - self.view.frame.size.width;
		[self.view setNeedsUpdateConstraints];
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		oldPanel.view.hidden = YES;
	}];
}

-(void)orientationDidChange:(NSNotification*)note
{
	CGRect r = self.view.frame;
	BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	if (isLandscape) {
		r.size.width =1024;
	} else {
		r.size.width = 768;
	}
	self.view.frame = r;
}
@end
