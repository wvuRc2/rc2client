//
//  RCMTextPrintView.m
//  MacClient
//
//  Created by Mark Lilback on 12/19/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMTextPrintView.h"

@interface RCMTextPrintView()
@property (nonatomic, strong) NSTextView *textView;
@end

@implementation RCMTextPrintView

-(id)init
{
	self = [super initWithFrame:[NSPrintInfo sharedPrintInfo].imageablePageBounds];
//	self.textView = [[NSTextView alloc] initWithFrame:NSInsetRect(self.bounds, 2, 2)];
//	[self addSubview:self.textView];
	[self setVerticallyResizable:YES];
	[self setHorizontallyResizable:NO];
	return self;
}

-(NSAttributedString*)textContent
{
	return self.attributedString;
}

-(void)setTextContent:(NSAttributedString *)textContent
{
	[self.textStorage setAttributedString:textContent];
	[self sizeToFit];
}

@synthesize jobName;
@synthesize textView;
@end
