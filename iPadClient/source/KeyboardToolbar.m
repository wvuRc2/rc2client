//
//  KeyboardToolbar.h
//  iPadClient
//
//  Created by Mark Lilback on 6/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "KeyboardToolbar.h"
#import <QuartzCore/QuartzCore.h>
#import "GradientButton.h"

#define kTagExecute 1001

@interface KeyboardToolbar()
@property (nonatomic, strong) UIView *buttonView;
@property (nonatomic, strong) GradientButton *executeButton;
@property (nonatomic, copy) NSArray *buttonColors;
@property (nonatomic, copy) NSArray *buttonColorsHighlighted;
@property (nonatomic, copy) NSArray *panels;
@property (nonatomic, strong) NSMutableDictionary *tagsToKeyStrings;
@property (nonatomic, strong) UIView *currentPanel;
@property (nonatomic) NSInteger currentPanelIndex;
@end

@implementation KeyboardToolbar 

-(id)init
{
	if ((self = [super init])) {
		UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 53)];
		self.view = v;
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		v.backgroundColor = [UIColor colorWithHexString:@"9c9ca6"];
		[self cacheGradients];
		self.executeButton = [self buttonWithFrame:CGRectMake(1024-90, 5, 80, 40)];
		[self.executeButton setTitle:@"Execute" forState:UIControlStateNormal];
		self.executeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		self.executeButton.tag = kTagExecute;
		[v addSubview:self.executeButton];
		UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024-100, 53)];
		buttonView.autoresizingMask = 0;
		buttonView.layer.masksToBounds=YES;
		[self.view addSubview:buttonView];
		self.buttonView = buttonView;
		self.tagsToKeyStrings = [NSMutableDictionary dictionary];
		NSArray *panelDicts = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyToolbar"];
		NSMutableArray *panelViews = [NSMutableArray arrayWithCapacity:panelDicts.count];
		for (NSDictionary *panelDict in panelDicts)
			[panelViews addObject:[self panelViewForDict:panelDict]];
		self.panels = panelViews;
		[self switchToPanel:self.panels.firstObject toTheLeft:YES];
		UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToLeft:)];
		leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
		leftSwipe.numberOfTouchesRequired = 1;
		leftSwipe.delaysTouchesBegan = YES;
		leftSwipe.cancelsTouchesInView = YES;
		[v addGestureRecognizer:leftSwipe];
		UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToRight:)];
		rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
		rightSwipe.numberOfTouchesRequired = 1;
		rightSwipe.delaysTouchesBegan = YES;
		rightSwipe.cancelsTouchesInView = YES;
		[v addGestureRecognizer:rightSwipe];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)orientationDidChange:(NSNotification*)note
{
	CGRect r = self.buttonView.frame;
	if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
		r.size.width = 924;
	else
		r.size.width = 668;
	self.buttonView.frame = r;
}

-(void)switchToPanel:(UIView*)panel toTheLeft:(BOOL)toTheLeft
{
	CGRect r = self.buttonView.bounds;
	r.size.width -= 100;
	r.origin.x = 10;
	panel.frame = r;
	if (self.currentPanel) {
		UIView *oldView = self.currentPanel;
		CGFloat viewWidth = self.buttonView.bounds.size.width;
		CGRect nDestRect = r;
		CGRect nStartRect = r;
		CGRect oDestRect = oldView.frame;
		if (toTheLeft) {
			nStartRect.origin.x += viewWidth + 10;
			oDestRect.origin.x -= viewWidth + 10;
		} else {
			nStartRect.origin.x -= viewWidth + 10;
			oDestRect.origin.x += viewWidth + 10;
		}
		panel.frame = nStartRect;
		[self.buttonView addSubview:panel];
		[UIView animateWithDuration:0.5 animations:^{
			panel.frame = nDestRect;
			oldView.frame = oDestRect;
		} completion:^(BOOL completed) {
			[oldView removeFromSuperview];
		}];
	} else {
		[self.buttonView addSubview:panel];
	}
	self.currentPanel = panel;
	self.currentPanelIndex = [self.panels indexOfObject:panel];
}

-(UIView*)panelViewForDict:(NSDictionary*)dict
{
	static dispatch_once_t onceToken;
	static NSInteger sNextTag;
	dispatch_once(&onceToken, ^{
		sNextTag = 10000;
	});
	UIView *pview = [[UIView alloc] initWithFrame:self.view.bounds];
	CGRect r = CGRectMake(10, 5, 60, 40);
	if ([[dict objectForKey:@"ButtonWidth"] integerValue] > 0)
		r.size.width = [[dict objectForKey:@"ButtonWidth"] integerValue];
	for (NSDictionary *btnDict in [dict objectForKey:@"Buttons"]) {
		CGRect btnFrame = r;
		NSInteger customWidth = [[btnDict objectForKey:@"Width"] integerValue];
		if (customWidth > 0)
			btnFrame.size.width = customWidth;
		GradientButton *btn = [self buttonWithFrame:btnFrame];
		[btn setTitle:[btnDict objectForKey:@"Title"] forState:UIControlStateNormal];
		NSString *bstr = [btnDict objectForKey:@"String"];
		if (nil == bstr)
			bstr = [btnDict objectForKey:@"Title"];
		btn.tag = ++sNextTag;
		[self.tagsToKeyStrings setObject:bstr forKey:[NSNumber numberWithInteger:btn.tag]];
		[pview addSubview:btn];
		r.origin.x += 10 + btnFrame.size.width;
	}
	return pview;
}

-(void)swipeToLeft:(UIGestureRecognizer*)gesture
{
	NSInteger idx = self.currentPanelIndex - 1;
	if (idx < 0)
		idx = self.panels.count - 1;
	[self switchToPanel:[self.panels objectAtIndex:idx] toTheLeft:YES];
}

-(void)swipeToRight:(UIGestureRecognizer*)gesture
{
	NSInteger idx = self.currentPanelIndex + 1;
	if (idx >= self.panels.count)
		idx = 0;
	[self switchToPanel:[self.panels objectAtIndex:idx] toTheLeft:NO];
}

-(IBAction)buttonNotPressed:(id)sender
{
	[sender setSelected:NO];
	[sender setHighlighted:NO];
}

-(IBAction)buttonPressed:(id)sender
{
	if ([sender tag] == kTagExecute) {
		[self.delegate keyboardToolbarExecute:self];
	} else {
		NSString *str = [self.tagsToKeyStrings objectForKey:[NSNumber numberWithInteger:[sender tag]]];
		[self.delegate keyboardToolbar:self insertString:str];
	}
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[sender setSelected:NO];
		[sender setHighlighted:NO];
	});
}

-(GradientButton*)buttonWithFrame:(CGRect)frame
{
	GradientButton *button = [[GradientButton alloc] initWithFrame:frame];
	button.normalGradientLocations = ARRAY([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1.0]);
	button.highlightGradientLocations = button.normalGradientLocations;
	button.normalGradientColors = self.buttonColors;
	button.highlightGradientColors = self.buttonColorsHighlighted;
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
	button.cornerRadius = 6;
	button.layer.masksToBounds = NO;
	button.layer.shadowColor = [UIColor blackColor].CGColor;
	button.layer.shadowOffset = CGSizeMake(1, 3);
	button.layer.shadowOpacity = 0.8;
	button.layer.shadowRadius = 1;
	[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:self action:@selector(buttonNotPressed:) forControlEvents:UIControlEventTouchUpOutside];
	return button;
}

-(void)cacheGradients
{
	NSMutableArray *a = [NSMutableArray array];
	UIColor *startC = [UIColor colorWithRed:0.933 green:0.933 blue:0.941 alpha:1.0];
	UIColor *endC = [UIColor colorWithRed:0.827 green:0.827 blue:0.851 alpha:1.0];
	[a addObject:(__bridge id)startC.CGColor];
	[a addObject:(__bridge id)endC.CGColor];
	self.buttonColors = a;
	[a removeAllObjects];
	startC = [UIColor colorWithRed:0.690 green:0.698 blue:0.725 alpha:1.0];
	endC = [UIColor colorWithRed:0.514 green:0.522 blue:0.140 alpha:1.0];
	[a addObject:(__bridge id)startC.CGColor];
	[a addObject:(__bridge id)endC.CGColor];
	self.buttonColorsHighlighted = a;
}

@synthesize delegate=_delegate;
@synthesize view=_view;
@synthesize buttonView=_buttonView;
@synthesize executeButton=_executeButton;
@synthesize buttonColors=_buttonColors;
@synthesize buttonColorsHighlighted=_buttonColorsHighlighted;
@synthesize panels=_panels;
@synthesize tagsToKeyStrings=_tagsToKeyStrings;
@synthesize currentPanel=_currentPanel;
@synthesize currentPanelIndex=_currentPanelIndex;
@end
