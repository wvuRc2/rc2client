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
#import <objc/runtime.h>

#define kTagExecute 1001

@interface ButtonPanel : UIView
@property (nonatomic, copy) NSString *panelName;
@end

@interface KeyboardButton : GradientButton
@property (copy) NSString *string;
@property CGRect landscapeFrame;
@property CGRect portraitFrame;
@property (assign) SEL selector;
-(void)setupWithDictionary:(NSDictionary*)dict;
@end

@interface KeyboardToolbar()
@property (nonatomic, strong) UIView *buttonView;
@property (nonatomic, copy) NSArray *buttonColors;
@property (nonatomic, copy) NSArray *buttonColorsHighlighted;
@property (nonatomic, copy) NSArray *panels;
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
		UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024-10, 53)];
		buttonView.autoresizingMask = 0;
		buttonView.layer.masksToBounds=YES;
		[self.view addSubview:buttonView];
		self.buttonView = buttonView;
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
	BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	if (isLandscape)
		r.size.width = 1014;
	else
		r.size.width = 758;
	self.buttonView.frame = r;
	for (UIView *aView in self.currentPanel.subviews) {
		if (![aView isKindOfClass:[KeyboardButton class]])
			continue;
		KeyboardButton *kbtn = (KeyboardButton*)aView;
		kbtn.frame = isLandscape ? kbtn.landscapeFrame : kbtn.portraitFrame;
	}
}

-(void)switchToPanelForFileExtension:(NSString*)fileExtension
{
	NSString *panelName=nil;
	if (NSOrderedSame == [fileExtension caseInsensitiveCompare:@"Rnw"])
		panelName = @"Latex";
	if (panelName) {
		for (ButtonPanel *panel in self.panels) {
			if ([panel.panelName isEqualToString:panelName] && panel != self.currentPanel) {
				NSInteger idx = [self.panels indexOfObject:panel];
				[self switchToPanel:panel toTheLeft:self.currentPanelIndex > idx];
				return;
			}
		}
	} else {
		if (self.currentPanelIndex > 0)
			[self switchToPanel:[self.panels objectAtIndex:0] toTheLeft:YES];
	}
}

-(void)switchToPanel:(UIView*)panel toTheLeft:(BOOL)toTheLeft
{
	CGRect r = self.buttonView.bounds;
	r.size.width -= 2;
	r.origin.x = 2;
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

-(ButtonPanel*)panelViewForDict:(NSDictionary*)dict
{
	static dispatch_once_t onceToken;
	static NSInteger sNextTag;
	dispatch_once(&onceToken, ^{
		sNextTag = 10000;
	});
	BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
	ButtonPanel *pview = [[ButtonPanel alloc] initWithFrame:self.view.bounds];
	CGRect pRect = CGRectMake(6, 5, 56, 40);
	CGRect lRect = CGRectMake(6, 5, 80, 40);
	for (NSDictionary *btnDict in [dict objectForKey:@"Buttons"]) {
		if (nil == [btnDict objectForKey:@"Empty"]) {
			CGRect btnFrame = isLandscape ? lRect : pRect;
			KeyboardButton *btn = [self buttonWithFrame:btnFrame];
			[btn setupWithDictionary:btnDict];
			[btn setTitle:[btnDict objectForKey:@"Title"] forState:UIControlStateNormal];
			btn.tag = ++sNextTag;
			btn.portraitFrame = pRect;
			btn.landscapeFrame = lRect;
			[pview addSubview:btn];
		}
		pRect.origin.x += 13 + pRect.size.width;
		lRect.origin.x += 13 + lRect.size.width;
	}
	pview.panelName = [dict objectForKey:@"Name"];
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(IBAction)buttonPressed:(id)sender
{
	if ([sender isKindOfClass:[KeyboardButton class]]) {
		KeyboardButton *kbtn = sender;
		if (kbtn.string)
			[self.delegate keyboardToolbar:self insertString:kbtn.string];
		else if (kbtn.selector && [self.delegate respondsToSelector:kbtn.selector])
			[self.delegate performSelector:kbtn.selector];
	}
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[sender setSelected:NO];
		[sender setHighlighted:NO];
	});
}

#pragma clang diagnostic pop

-(KeyboardButton*)buttonWithFrame:(CGRect)frame
{
	KeyboardButton *button = [[KeyboardButton alloc] initWithFrame:frame];
	button.normalGradientLocations = ARRAY([NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1.0]);
	button.highlightGradientLocations = button.normalGradientLocations;
	button.normalGradientColors = self.buttonColors;
	button.highlightGradientColors = self.buttonColorsHighlighted;
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
	button.cornerRadius = 6;
	button.layer.masksToBounds = NO;
	button.layer.shadowColor = [UIColor blackColor].CGColor;
	button.layer.shadowOffset = CGSizeMake(1, 1);
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

@end

@implementation KeyboardButton
-(void)setupWithDictionary:(NSDictionary*)dict
{
	self.string = [dict objectForKey:@"String"];
	if (nil == self.string)
		self.string = [dict objectForKey:@"Title"];
	if ([dict objectForKey:@"Selector"]) {
		self.selector = NSSelectorFromString([dict objectForKey:@"Selector"]);
		self.string = nil;
	}
}
@end

@implementation ButtonPanel
@end
