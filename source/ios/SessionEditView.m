//
//  SessionEditView.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "SessionEditView.h"

@implementation SessionEditView

-(void)keyboardVisible:(NSNotification*)note
{
	BOOL isLand = UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation);
	if (isLand) {
		NSDictionary *userInfo = [note userInfo];
		CGSize kbsize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, kbsize.width, 0);
		self.contentInset = insets;
		self.scrollIndicatorInsets = insets;
	}
}

-(void)keyboardHiding:(NSNotification*)note
{
	self.contentInset = UIEdgeInsetsZero;
	self.scrollIndicatorInsets = UIEdgeInsetsZero;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	UIMenuController *mc = [UIMenuController sharedMenuController];
	mc.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeSelection:)],
						  [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)]];
	[[NSNotificationCenter defaultCenter] addObserver:self
										 selector:@selector(keyboardVisible:)
											 name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
										 selector:@selector(keyboardHiding:)
											 name:UIKeyboardWillHideNotification object:nil];
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.autocorrectionType = UITextAutocorrectionTypeNo;
	self.layer.masksToBounds=YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(showHelp:) || action == @selector(executeSelection:))
		return YES;
	return [super canPerformAction:action withSender:sender];
}

-(void)upArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionUp offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)downArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionDown offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)leftArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionLeft offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
}

-(void)rightArrow
{
	UITextPosition *pos = self.selectedTextRange.start;
	pos = [self positionFromPosition:pos inDirection:UITextLayoutDirectionRight offset:1];
	UITextRange *rng = [self textRangeFromPosition:pos toPosition:pos];
	self.selectedTextRange = rng;
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

-(void)setDefaultFontName:(NSString*)fontName size:(CGFloat)fontSize
{
	self.font = [UIFont fontWithName:fontName size:fontSize];
}

-(BOOL)isEditorFirstResponder
{
	return self.isFirstResponder;
}

-(BOOL)inputAccessoryVisible
{
	return self.inputAccessoryView.hidden;
}

-(void)setInputAccessoryVisible:(BOOL)inputAccessoryVisible
{
	self.inputAccessoryView.hidden = inputAccessoryVisible;
}

-(NSString*)string
{
	return self.text;
}

-(void)setString:(NSString *)string
{
	self.text = string;
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

@synthesize helpBlock;
@synthesize executeBlock;
@end
