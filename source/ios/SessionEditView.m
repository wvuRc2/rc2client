//
//  SessionEditView.m
//  iPadClient
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "SessionEditView.h"

@implementation SessionEditView

-(void)awakeFromNib
{
	[super awakeFromNib];
	UIMenuController *mc = [UIMenuController sharedMenuController];
	UIMenuItem *mi = [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)];
	NSArray *items = [NSArray arrayWithObject:mi];
	mc.menuItems = items;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(showHelp:))
		return YES;
	return [super canPerformAction:action withSender:sender];
}

-(IBAction)showHelp:(id)sender
{
	if (self.helpBlock)
		self.helpBlock(self);
}

-(NSAttributedString*)attributedString
{
	if ([self respondsToSelector:@selector(attributedText)])
		return [self attributedText];
	return [[NSAttributedString alloc] initWithString:self.text];
}

-(void)setAttributedString:(NSAttributedString *)attributedString
{
	if ([self respondsToSelector:@selector(attributedText)])
		self.attributedText = attributedString;
	else
		self.text = attributedString.string;
}

@synthesize helpBlock=_helpBlock;
@end
