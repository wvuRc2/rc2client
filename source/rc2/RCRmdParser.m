//
//  RCRmdParser.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/17/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCRmdParser.h"
#import "RCChunk.h"
#import "RCCodeHighlighterR.h"
#import "RCCodeHighlighterLatex.h"
#import "Rc2AppConstants.h"

@interface RCRmdParser ()
@property (nonatomic, strong) RCCodeHighlighterLatex *latexHighlighter;
@property (nonatomic, strong) NSRegularExpression *rmdChunkRegex;
@property (nonatomic, strong) NSRegularExpression *rmdInlineChunkRegex;
@property (nonatomic, strong) NSRegularExpression *rmdEquationRegex;
@property (nonatomic, strong) NSRegularExpression *jaxEquationRegex;
@property (nonatomic, strong) NSRegularExpression *quoteRegex;
@property (nonatomic, copy) NSArray *myChunks;

@end

@implementation RCRmdParser

- (id)init
{
	if ((self = [super init])) {
		NSError *err;
		self.rmdChunkRegex = [NSRegularExpression regularExpressionWithPattern:@"\n```\\{r\\s*([^\\}]*)\\}\\s*\n+(.*?)\n```\n"
																	   options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.rmdInlineChunkRegex = [NSRegularExpression regularExpressionWithPattern:@"`r\\s+([^`]*)`"
																			 options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)//(?:(?:\$\$?)(?:latex)?(.*?)(\1))|((\\\()(.*?)$1)n      (?:(\$\$?)(?:latex)?(.*?)(\1))
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.rmdEquationRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:(\\$\\$?)(?:latex)?(.*?)(\\1))"
																		  options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.jaxEquationRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:\\\\\\{\\s+(.*?)\\\\\\})|(\\\\\\(\\s+(.*?)\\\\\\))"
																		  options:NSRegularExpressionDotMatchesLineSeparators error:&err];

		if (err)
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.codeHighlighter = [[RCCodeHighlighterR alloc] init];
		self.latexHighlighter = [[RCCodeHighlighterLatex alloc] init];
	}
	return self;
}

-(void)performSetup
{
	[super performSetup];
	self.codeHighlighter.colorMap = self.colorMap;
	self.docHighlighter.colorMap = self.colorMap;
	self.latexHighlighter.colorMap = self.colorMap;
}

-(void)parseRange:(NSRange)range
{
	NSString *str = self.textStorage.string;
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
	
	//code blocks
	__block NSUInteger docBlockStart=0;
	__block int nextChunkIndex=1;
	[self.rmdChunkRegex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length)
									  usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 if (results.range.location - docBlockStart > 0) {
			 //add previous doc chunk
			 RCChunk *docChunk = [RCChunk documentationChunkWithNumber:nextChunkIndex++];
			 docChunk.parseRange = NSMakeRange(docBlockStart, results.range.location - docBlockStart);
			 [chunks addObject:docChunk];
		 }
		 NSString *cname = nil;
		 if ([results rangeAtIndex:1].length > 0)
			 cname = [str substringWithRange:[results rangeAtIndex:1]];
		 RCChunk *codeChunk = [RCChunk codeChunkWithNumber:nextChunkIndex++ name:cname];
		 codeChunk.parseRange = [results rangeAtIndex:2];
		 [chunks addObject:codeChunk];
		 docBlockStart = results.range.location + results.range.length;
		 
		 //mark any chunk title as a comment
//		 if ([results rangeAtIndex:1].length > 0)
//			 [astr setAttributes:self.commentAttrs range:[results rangeAtIndex:1]];
	 }];
	if (docBlockStart < str.length) {
		RCChunk *finalChunk = [RCChunk documentationChunkWithNumber:nextChunkIndex];
		finalChunk.parseRange = NSMakeRange(docBlockStart, str.length - docBlockStart);
		[chunks addObject:finalChunk];
	}
	//	[self adjustParseRanges:chunks fullRange:range];
	[self colorChunks:chunks];
	ColorClass *color = [self.colorMap objectForKey:kPref_SyntaxColor_InlineBackground];
	[self.rmdInlineChunkRegex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length)
											usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [self.textStorage addAttribute:NSBackgroundColorAttributeName value:color range:results.range];
		 [self.codeHighlighter highlightText:self.textStorage range:[results rangeAtIndex:1]];
	 }];
	
	//display equation blocks
	color = [[self.colorMap objectForKey:kPref_SyntaxColor_EquationBackground] colorWithAlphaComponent:0.4];
	[self.rmdEquationRegex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length)
										 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [self.textStorage addAttribute:NSBackgroundColorAttributeName value:color range:results.range];
		 [self.latexHighlighter highlightText:self.textStorage range:[results rangeAtIndex:1]];
	 }];
	[self.jaxEquationRegex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length)
										 usingBlock:^(NSTextCheckingResult *results, NSMatchingFlags flags, BOOL *stop)
	 {
		 [self.textStorage addAttribute:NSBackgroundColorAttributeName value:color range:results.range];
		 [self.latexHighlighter highlightText:self.textStorage range:results.range];
	 }];
	
	self.myChunks = chunks;
}

-(NSArray*)chunks
{
	return self.myChunks;
}
@end
