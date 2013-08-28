//
//  FunctionVariableSummaryCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "FunctionVariableSummaryCell.h"
#import "RCVariable.h"

@interface FunctionVariableSummaryCell ()
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation FunctionVariableSummaryCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{

	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
	}
	return self;
}

-(void)prepareForReuse
{
	[super prepareForReuse];
	self.variable=nil;
	[self updateFonts];
}

-(void)updateFonts
{
	UIFontDescriptor *fd = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
	self.textView.font = [UIFont fontWithName:@"Courier" size:fd.pointSize];
}

-(void)setVariable:(RCVariable *)variable
{
	_variable = variable;
	self.textView.text = variable.functionBody;
}

-(NSInteger)customRowHeight
{
	return 297;
}

@end
