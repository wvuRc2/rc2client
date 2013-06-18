//
//  RichSessionEditor.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/7/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RichSessionEditor.h"
#import <DTRichTextEditor/DTRichTextEditor.h>

@interface RichSessionEditor() <DTRichTextEditorViewDelegate> 
@property CGRect initialFrame;
@property (strong) DTRichTextEditorView *richEditor;
@end

@implementation RichSessionEditor
-(id)initWithFrame:(CGRect)frame
{
	if ((self = [super init])) {
		self.initialFrame = frame;
	}
	return self;
}

-(void)loadView
{
	UIView *view = [[UIView alloc] initWithFrame:self.initialFrame];
	self.richEditor = [[DTRichTextEditorView alloc] initWithFrame:view.bounds];
	self.richEditor.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[view addSubview:self.richEditor];
	self.view = view;
	self.menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Execute" action:@selector(executeSelection:)],
				   [[UIMenuItem alloc] initWithTitle:@"Help" action:@selector(showHelp:)]];
	UIMenuController *mc = [UIMenuController sharedMenuController];
	NSLog(@"menu=%@", mc.menuItems);
	self.richEditor.editorViewDelegate = self;
	NSLog(@"menu=%@", mc.menuItems);
}

-(UIView*)view
{
	return self.richEditor;
}

-(void)upArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionUp offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

-(void)downArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionDown offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}


-(void)leftArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionLeft offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}


-(void)rightArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionRight offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

-(BOOL)editorView:(DTRichTextEditorView *)editorView canPerformAction:(SEL)action withSender:(id)sender
{
	return action == @selector(showHelp:) || action == @selector(executeSelection:);
}

-(void)resignFirstResponder
{
	[self.richEditor resignFirstResponder];
}


-(void)becomeFirstResponder
{
	[self.richEditor becomeFirstResponder];
}


-(NSString*)string
{
	return self.richEditor.attributedString.string;
}

-(void)setString:(NSString *)string
{
	self.richEditor.attributedString = [[NSAttributedString alloc] initWithString:string];
}

-(NSAttributedString*)attributedString
{
	return self.richEditor.attributedString;
}

-(void)setAttributedString:(NSAttributedString *)attributedString
{
	self.richEditor.attributedString = attributedString;
}

-(BOOL)inputAccessoryVisible
{
	return self.richEditor.inputAccessoryView.hidden;
}

-(void)setInputAccessoryVisible:(BOOL)inputAccessoryVisible
{
	self.richEditor.inputAccessoryView.hidden = inputAccessoryVisible;
}

-(UIView*)inputAccessoryView
{
	return self.richEditor.inputAccessoryView;
}

-(void)setInputAccessoryView:(UIView *)inputAccessoryView
{
	self.richEditor.inputAccessoryView = inputAccessoryView;
}

-(NSRange)selectedRange
{
	return [(DTTextRange*)self.richEditor.selectedTextRange NSRangeValue];
}

-(void)setSelectedRange:(NSRange)selectedRange
{
	DTTextRange *rng = [DTTextRange rangeWithNSRange:selectedRange];
	self.richEditor.selectedTextRange = rng;
}

-(BOOL)isEditorFirstResponder
{
	return self.richEditor.isFirstResponder;
}

-(BOOL)editable
{
	return self.richEditor.editable;
}

-(void)setEditable:(BOOL)editable
{
	self.richEditor.editable = editable;
}

-(void)setDefaultFontName:(NSString*)fontName size:(CGFloat)fontSize
{
	self.richEditor.defaultFontFamily = fontName;
	self.richEditor.defaultFontSize = fontSize;
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

@synthesize helpBlock;
@synthesize executeBlock;
@synthesize menuItems;
@end
