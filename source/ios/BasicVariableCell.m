//
//  BasicVariableCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "BasicVariableCell.h"

@interface BasicVariableCell ()
@end

@implementation BasicVariableCell

-(void)updateFonts
{
	self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	self.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

-(void)prepareForReuse
{
	[super prepareForReuse];
	[self updateFonts];
}
@end
