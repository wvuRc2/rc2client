//
//  LineNumberView.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/18/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "LineNumberView.h"
#import <DTRichTextEditor/DTRichTextEditor.h>

@implementation LineNumberView

-(id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor colorWithHexString:@"eeeeee"];
	}
	return self;
}

-(void)drawRect:(CGRect)rect
{
	NSArray *visLines = self.editor.visibleLayoutLines;
	UIFont *fnt = [UIFont systemFontOfSize:self.editor.defaultFontSize];
	CGFloat vertOffset = fnt.xHeight;//self.editor.contentOffset.y + self.editor.contentInset.top + fnt.lineHeight;
	NSString *string = self.editor.attributedText.string;
	NSInteger lastGraph = 0;
	for (DTCoreTextLayoutLine *line in visLines) {
		CGRect f = line.frame;
		f.origin.x = 2;
		f.origin.y += vertOffset;
		f.size.width = 16;
		NSRange strRange = [line stringRange];
		if (strRange.location + strRange.length >= string.length)
			NSLog(@"found it");
		NSRange lineRange = [string lineRangeForRange:strRange];
		NSString *lineStr = [string substringWithRange:strRange];
		NSLog(@"sr=%@, lr=%@, str=%@", NSStringFromRange(strRange), NSStringFromRange(lineRange), lineStr);
		NSInteger gnum = [_editor.attributedTextContentView.layoutFrame paragraphIndexContainingStringIndex:strRange.location]+1;
		if (gnum > lastGraph) {
			NSString *lnstr = [NSString stringWithFormat:@"%d", gnum];
			[lnstr drawInRect:f withFont:fnt];
			lastGraph = gnum;
		}
	}
}

-(void)editorContentChanged
{
	[self setNeedsDisplay];
}

@end
