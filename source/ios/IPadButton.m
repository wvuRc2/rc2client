//
//  IPadButton.m
//  iPadClient
//
//  Created by Mark Lilback on 8/29/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "IPadButton.h"

@implementation IPadButton
@synthesize isLightStyle=_isLightStyle;

- (void)addShineLayer 
{
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = self.layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:0.8f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:0.8f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.3f],
                            [NSNumber numberWithFloat:0.3f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [self.layer addSublayer:shineLayer];
}

-(void)setupButton
{
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
	self.titleLabel.textColor = self.isLightStyle ? [UIColor blackColor] : [UIColor whiteColor];
	UIImage *imgNormal = [UIImage imageNamed: self.isLightStyle ? @"buttonLight" : @"button"];
	UIImage *imgStretched = [imgNormal stretchableImageWithLeftCapWidth:6 topCapHeight:0];
	[self setBackgroundImage:imgStretched forState:UIControlStateNormal];
	imgNormal = [UIImage imageNamed: self.isLightStyle ? @"buttonLightPressed" : @"buttonPressed"];
	imgStretched = [imgNormal stretchableImageWithLeftCapWidth:6 topCapHeight:0];
	[self setBackgroundImage:imgStretched forState:UIControlStateHighlighted];
	[self addShineLayer];
}

-(id)init
{
	self = [super init];
	[self setupButton];
	return self;
}

- (void)didMoveToSuperview
{
	[self setupButton];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	[self setupButton];
}

-(void)setIsLightStyle:(BOOL)val
{
	_isLightStyle=val;
	[self setupButton];
}
@end
