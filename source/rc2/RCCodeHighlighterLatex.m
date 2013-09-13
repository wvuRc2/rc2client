//
//  RCCodeHighlighterLatex.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCCodeHighlighterLatex.h"
#import "AppConstants.h"
#import <ParseKit/ParseKit.h>

@interface RCCodeHighlighterLatex ()
@property (nonatomic, strong) NSRegularExpression *commentRegex;
@end

@implementation RCCodeHighlighterLatex

-(id)init
{
	if ((self = [super init])) {
		NSError *err;
		self.commentRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\\\)(%.*\n)" options:0 error:&err];
		if (err)
			Rc2LogError(@"error compiling latex comment regex: %@", err);
		if (err)
			Rc2LogError(@"error compiling latex keyword regex: %@", err);
		
	}
	return self;
}

-(void)highlightText:(NSMutableAttributedString *)content range:(NSRange)range
{
	[content removeAttribute:NSForegroundColorAttributeName range:range]; //remove old colors
	NSString *sourceStr = [content.string substringWithRange:range];

	id color = [self.colorMap objectForKey:kPref_SyntaxColor_Comment];
	if (color) {
		[self.commentRegex enumerateMatchesInString:sourceStr options:0 range:NSMakeRange(0, sourceStr.length)
											  usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
		 {
			 [content addAttribute:NSForegroundColorAttributeName value:color range:[results rangeAtIndex:1]];
		 }];
	}
	
	
	PKTokenizer *t = [[PKTokenizer alloc] initWithString:sourceStr];
	[t setTokenizerState:t.symbolState from:'/' to:'/'];
	[t.commentState addSingleLineStartMarker:@"#"];
	[t.symbolState add:@"<-"];
	[t.symbolState remove:@":-"];
	[t.commentState setReportsCommentTokens:YES];
	[t setTokenizerState:t.commentState from:'#' to:'#'];
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil, *lastToken=nil;
	while ((token = [t nextToken]) != eof) {
		NSRange rng = NSMakeRange(range.location + token.offset, token.stringValue.length);
		color=nil;
		BOOL isKeyword=NO;
		switch (token.tokenType) {
			case PKTokenTypeComment:
				color = [colorMap objectForKey:kPref_SyntaxColor_Comment];
				break;
			case PKTokenTypeQuotedString:
				color = [colorMap objectForKey:kPref_SyntaxColor_Quote];
				break;
			case PKTokenTypeSymbol:
//				color = [colorMap objectForKey:kPref_SyntaxColor_Symbol];
				break;
			case PKTokenTypeWord:
//				NSLog(@"prev=%@, now=%@", [lastToken debugDescription], [token debugDescription]);
				if ((lastToken.tokenType == PKTokenTypeSymbol) && [lastToken.stringValue characterAtIndex:0] == '\\') {
//					NSLog(@"using symbol %@", token.stringValue);
					isKeyword = YES;
					color = [colorMap objectForKey:kPref_SyntaxColor_Keyword];
				}
				break;
			default:
				break;
		}
		if (color) {
			if (isKeyword) {
				rng.location -= 1;
				rng.length += 1;
			}
			if (!(token.tokenType == PKTokenTypeSymbol && [token.stringValue characterAtIndex:0] == '\\')) {
				[content addAttribute:NSForegroundColorAttributeName value:color range:rng];
			}
		}
		lastToken = token;
	}
}

@synthesize colorMap;

@end
