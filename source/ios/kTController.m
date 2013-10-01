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
@property (nonatomic, strong, readwrite) IBOutlet UIView *view;
@property (nonatomic, weak) IBOutlet UIView *panelView;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, weak) IBOutlet UIButton *prevButton;
@property (nonatomic, assign) NSUInteger currentPanelIndex;
@end

@interface KTButton : UIButton
@end

@implementation KTButton
@end

@interface kTControllerView : UIView
@end

@implementation kTControllerView

//not sure why this has to be overridden. super's implemetation is wrong
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	for (UIView *view in self.subviews) {
		if (CGRectContainsPoint(view.frame, point))
			return YES;
	}
	return NO;
}

@end

@implementation kTController

- (id)init
{
	if ((self = [super init])) {
		UINib *nib = [UINib nibWithNibName:@"KTController" bundle:nil];
		[nib instantiateWithOwner:self options:nil];
		self.view.frame = CGRectMake(0, 3, 1024, 51);
		self.view.translatesAutoresizingMaskIntoConstraints = NO;
		self.panelView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.panelView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.nextButton attribute:NSLayoutAttributeTop multiplier:1 constant:2]];

		NSMutableArray *panels = [NSMutableArray array];
		for (NSString *aNib in @[@"KTExecutePanel", @"KTLatexPanel"]) {
			KTPanel *panel = [[KTPanel alloc] initWithNibName:aNib controller:self];
			[panels addObject:panel];
			[self.panelView addSubview:panel.view];
			NSLayoutConstraint *xcon = [NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.panelView attribute:NSLayoutAttributeLeft multiplier:1 constant:-1024];
			[self.panelView addConstraint:xcon];
			panel.xConstraint = xcon;
			[self.panelView addConstraint:[NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.panelView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
			[self.panelView addConstraint:[NSLayoutConstraint constraintWithItem:panel.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.panelView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
		}
		self.panels = panels;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

		UIInputView *iview = [[UIInputView alloc] initWithFrame:self.view.frame inputViewStyle:UIInputViewStyleDefault];
		[iview addSubview:self.view];
		[iview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_view)]];
		[iview addConstraint: [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:iview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
		self.inputView = iview;

		KTPanel *first = [panels objectAtIndex:0];
		first.xConstraint.constant = 0;
		[self orientationDidChange:nil]; //force initial sizing
		
		self.nextButton.userInteractionEnabled = YES;
}
	return self;
}

-(IBAction)nextPanel:(id)sender
{
	NSUInteger idx = self.currentPanelIndex + 1;
	if (idx >= self.panels.count)
		idx = 0;
	KTPanel *oldPanel = self.panels[self.currentPanelIndex];
	KTPanel *panel = self.panels[idx];
	self.currentPanelIndex = idx;

	CGFloat width = self.panelView.frame.size.width;
	[UIView performWithoutAnimation:^{
		panel.xConstraint.constant = - width;
		[self.panelView setNeedsUpdateConstraints];
		[self.panelView layoutIfNeeded];
		panel.view.hidden = NO;
	}];
	
	[UIView animateWithDuration:0.5 animations:^{
		panel.xConstraint.constant = 0;
		oldPanel.xConstraint.constant = width;
		[self.panelView setNeedsUpdateConstraints];
		[self.panelView layoutIfNeeded];
	} completion:^(BOOL finished) {
		oldPanel.view.hidden = YES;
	}];
}

-(IBAction)previousPanel:(id)sender
{
	NSInteger idx = self.currentPanelIndex - 1;
	if (idx < 0)
		idx = self.panels.count - 1;
	KTPanel *oldPanel = self.panels[self.currentPanelIndex];
	KTPanel *panel = self.panels[idx];
	self.currentPanelIndex = idx;

	CGFloat width = self.panelView.frame.size.width;
	[UIView performWithoutAnimation:^{
		panel.view.hidden = NO;
		panel.xConstraint.constant = width;
		[self.panelView setNeedsUpdateConstraints];
		[self.panelView layoutIfNeeded];
	}];
	
	[UIView animateWithDuration:0.5 animations:^{
		panel.xConstraint.constant = 0;
		oldPanel.xConstraint.constant = - width;
		[self.panelView setNeedsUpdateConstraints];
		[self.panelView layoutIfNeeded];
	} completion:^(BOOL finished) {
		oldPanel.view.hidden = YES;
	}];
}

-(void)orientationDidChange:(NSNotification*)note
{
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	if (isLandscape) {
		r.size.width =1024;
	} else {
		r.size.width = 768;
	}
	self.view.frame = r;
}
@end
