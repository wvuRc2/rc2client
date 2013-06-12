//
//  RichSessionEditor.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/7/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RichSessionEditor.h"
#import <DTRichTextEditor/DTRichTextEditor.h>

@interface RichSessionEditor ()
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
//	self.richEditor.textDelegate = self;
	[view addSubview:self.richEditor];
	self.view = view;
}

-(UIView*)view
{
	return self.richEditor;
}

-(void)upArrow
{
	
}

-(void)downArrow
{
	
}


-(void)leftArrow
{
	
}


-(void)rightArrow
{
	
}



-(void)resignFirstResponder
{
	
}


-(void)becomeFirstResponder
{
	
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

@synthesize helpBlock;
@synthesize executeBlock;

@end
