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
	self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
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
		self.backgroundColor = [UIColor colorWithHexString:@"cbcbcb"];
		label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	} else {
		self.backgroundColor = [UIColor whiteColor];
		label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	}
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = NSTextAlignmentCenter;
	[self addSubview:label];
	self.label = label;
	self.label.text = self.content;
}

-(void)updateFont
{
	if (self.isHeader) {
		self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	} else {
		self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	}
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
