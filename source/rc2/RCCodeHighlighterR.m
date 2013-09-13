//
//  RCCodeHighlighterR.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCCodeHighlighterR.h"
#import <ParseKit/ParseKit.h>
#import "AppConstants.h"

@interface RCCodeHighlighterR ()

@end

@implementation RCCodeHighlighterR

+(NSSet*)keywords
{
	static NSSet *keys;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"RKeywords" withExtension:@"txt"];
		NSArray *keyArray = [[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
		NSAssert(keyArray, @"failed to load R keywords");
		keys = [[NSSet alloc] initWithArray:keyArray];
	});
	return keys;
}

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

-(void)highlightText:(NSMutableAttributedString *)content range:(NSRange)range
{
	[content removeAttribute:NSForegroundColorAttributeName range:range]; //remove old colors
	NSString *sourceStr = [content.string substringWithRange:range];
	NSRange nlRange = [sourceStr rangeOfString:@"\n"];
	NSAssert(nlRange.location != NSNotFound, @"failed to find newline on code chunk");
	if (nlRange.length > 0)
		sourceStr = [sourceStr substringFromIndex:nlRange.location + nlRange.length];

	PKTokenizer *t = [[PKTokenizer alloc] initWithString:sourceStr];
	[t setTokenizerState:t.symbolState from:'/' to:'/'];
	[t.commentState addSingleLineStartMarker:@"#"];
	[t.symbolState add:@"<-"];
	[t.symbolState remove:@":-"];
	[t.commentState setReportsCommentTokens:YES];
	[t setTokenizerState:t.commentState from:'#' to:'#'];
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	while ((token = [t nextToken]) != eof) {
		NSRange rng = NSMakeRange(range.location + nlRange.location + nlRange.length + token.offset, token.stringValue.length);
		id color=nil;
//		NSLog(@"tk=%@", token.debugDescription);
		switch (token.tokenType) {
			case PKTokenTypeComment:
				color = [colorMap objectForKey:kPref_SyntaxColor_Comment];
				break;
			case PKTokenTypeQuotedString:
				color = [colorMap objectForKey:kPref_SyntaxColor_Quote];
				break;
			case PKTokenTypeNumber:
//				color = [NSColor purpleColor];
				break;
			case PKTokenTypeSymbol:
				color = [colorMap objectForKey:kPref_SyntaxColor_Symbol];
				break;
			case PKTokenTypeWord:
				if ([[RCCodeHighlighterR keywords] containsObject:token.stringValue])
					color = [colorMap objectForKey:kPref_SyntaxColor_Keyword];
				break;
			default:
				break;
		}
		if (color)
			[content addAttribute:NSForegroundColorAttributeName value:color range:rng];
	}
}

@synthesize colorMap;
@end
