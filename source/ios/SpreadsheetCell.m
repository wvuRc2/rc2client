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
	if (nil == self.label) {
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
			label.font = [UIFont boldSystemFontOfSize:18.0];
		} else {
			self.backgroundColor = [UIColor whiteColor];
		}
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		[self addSubview:label];
		self.label = label;
	}
	self.label.text = self.content;
}


@end
