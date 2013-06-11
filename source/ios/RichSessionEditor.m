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
	self.richEditor.textDelegate = self;
	[view addSubview:self.richEditor];
	self.view = view;
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



-(void)setDefaultFontName:(NSString*)fontName size:(CGFloat)fontSize
{
	
}

@synthesize helpBlock;
@synthesize executeBlock;


@end
