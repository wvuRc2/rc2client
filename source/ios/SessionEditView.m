//
//  SessionEditView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SessionEditView.h"

@implementation SessionEditView

-(void)awakeFromNib
{
	[super awakeFromNib];
	UIMenuController *mc = [UIMenuController sharedMenuController];
	mc.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeSelection:)],
						  [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)]];
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(showHelp:) || action == @selector(executeSelection:))
		return YES;
	return [super canPerformAction:action withSender:sender];
}

-(IBAction)executeSelection:(id)sender
{
	if (self.executeBlock)
		self.executeBlock(self);
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
	if ([self respondsToSelector:@selector(attributedText)] && attributedString.length < 8200)
		self.attributedText = attributedString;
	else
		self.text = attributedString.string;
}

@end
