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
@property (nonatomic, strong) UINib *tbarNib;
@property (nonatomic, strong) GradientButton *executeButton;
@property (nonatomic, copy) NSArray *buttonColors;
@property (nonatomic, copy) NSArray *buttonColorsHighlighted;
@end

@implementation KeyboardToolbar 

-(id)init
{
	if ((self = [super init])) {
		self.tbarNib = [UINib nibWithNibName:@"KeyboardToolbar" bundle:[NSBundle mainBundle]];
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
	}
	return self;
}

-(IBAction)buttonPressed:(id)sender
{
	if ([sender tag] == kTagExecute) {
		[self.delegate keyboardToolbarExecute:self];
	}
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
@synthesize tbarNib=_tbarNib;
@synthesize executeButton=_executeButton;
@synthesize buttonColors=_buttonColors;
@synthesize buttonColorsHighlighted=_buttonColorsHighlighted;
@end
