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
