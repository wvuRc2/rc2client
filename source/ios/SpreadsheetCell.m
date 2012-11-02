//
//  SpreadsheetCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SpreadsheetCell.h"

@interface SpreadsheetCell ()
@property (nonatomic, weak) UILabel *label;
@property (nonatomic, weak) CAGradientLayer *bgLayer;
@end

@implementation SpreadsheetCell
-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	self.layer.borderWidth = 1.0;
	self.layer.borderColor = [UIColor grayColor].CGColor;
	return self;
}

-(void)didMoveToSuperview
{
	[super didMoveToSuperview];
	if (nil == self.label)
		[self setNeedsLayout];
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	[self.label removeFromSuperview];
	[self.bgLayer removeFromSuperlayer];
	UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
	if (self.isHeader) {
		CAGradientLayer *gl = [CAGradientLayer layer];
		gl.colors = @[
		(id)[UIColor colorWithWhite:0.9 alpha:1.0].CGColor,
		(id)[UIColor colorWithWhite:0.8 alpha:1.0].CGColor,
		(id)[UIColor colorWithWhite:0.6 alpha:1.0].CGColor,
		(id)[UIColor colorWithWhite:0.5 alpha:1.0].CGColor
		];
		gl.locations = @[@0.0, @0.02, @0.99, @1.0];
		gl.frame = self.bounds;
		[self.layer addSublayer:gl];
		self.bgLayer = gl;
		self.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:18.0];
	} else {
		self.backgroundColor = [UIColor whiteColor];
	}
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = NSTextAlignmentCenter;
	[self addSubview:label];
	self.label = label;
	self.label.text = self.content;
}

-(void)setIsHeader:(BOOL)isHeader
{
	_isHeader = isHeader;
	[self setNeedsLayout];
}

-(void)setContent:(NSString *)content
{
	if (![content isKindOfClass:[NSString class]])
		NSLog(@"bad data");
	_content = [content copy];
	self.label.text = content;
}

@end