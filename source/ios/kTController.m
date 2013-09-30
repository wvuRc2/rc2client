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
		NSMutableArray *panels = [NSMutableArray array];
		for (NSString *aNib in @[@"KTExecutePanel", @"KTLatexPanel"]) {
			KTPanel *panel = [[KTPanel alloc] initWithNibName:aNib controller:self];
			[panels addObject:panel];
		}
		self.panels = panels;

		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 53)];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

		UIInputView *iview = [[UIInputView alloc] initWithFrame:self.view.frame inputViewStyle:UIInputViewStyleDefault];
		[iview addSubview:self.view];
		self.inputView = iview;

		KTPanel *first = [panels objectAtIndex:0];
		[self.view addSubview:first.view];
		
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
	CGRect frame = self.view.bounds;

	//move newPanel offscreen w/o animation
	CGRect r = frame;
	r.origin.x += r.size.width;
	panel.view.frame = r;
	[self.view addSubview:panel.view];

	[UIView animateWithDuration:0.5 animations:^{
		CGRect oldRect = oldPanel.view.frame;
		oldRect.origin.x -= oldRect.size.width + 100;
		oldPanel.view.frame = oldRect;
		panel.view.frame = frame;
	} completion:^(BOOL finished) {
		[oldPanel.view removeFromSuperview];
	}];
	
}

-(void)previousPanel:(id)sender
{
	NSInteger idx = self.currentPanelIndex - 1;
	if (idx < 0)
		idx = 0;
	KTPanel *oldPanel = self.panels[self.currentPanelIndex];
	KTPanel *panel = self.panels[idx];
	self.currentPanelIndex = idx;
	CGRect frame = self.view.bounds;

	//move newPanel offscreen w/o animation
	CGRect r = frame;
	r.origin.x -= r.size.width;
	panel.view.frame = r;
	[self.view addSubview:panel.view];

	[UIView animateWithDuration:0.5 animations:^{
		CGRect oldRect = oldPanel.view.frame;
		oldRect.origin.x += oldRect.size.width + 100;
		oldPanel.view.frame = oldRect;
		panel.view.frame = frame;
	} completion:^(BOOL finished) {
		[oldPanel.view removeFromSuperview];
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
	[self.view setNeedsUpdateConstraints];
	for (UIView *v in self.view.subviews)
		[v setNeedsUpdateConstraints];
}
@end
