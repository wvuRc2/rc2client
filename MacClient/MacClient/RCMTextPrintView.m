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
	self.textView = [[NSTextView alloc] initWithFrame:self.bounds];
	[self addSubview:self.textView];
	[self.textView setVerticallyResizable:YES];
	[self.textView setHorizontallyResizable:NO];
	return self;
}

-(NSAttributedString*)textContent
{
	return self.textView.attributedString;
}

-(void)setTextContent:(NSAttributedString *)textContent
{
	[self.textView.textStorage setAttributedString:textContent];
}

@synthesize jobName;
@synthesize textView;
@end
