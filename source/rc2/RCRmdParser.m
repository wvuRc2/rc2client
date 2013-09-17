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

@interface RCRmdParser ()
@property (nonatomic, strong) NSRegularExpression *rmdChunkRegex;
@property (nonatomic, strong) NSRegularExpression *rmdInlineChunkRegex;
@property (nonatomic, strong) NSRegularExpression *rmdEquationRegex;
@property (nonatomic, strong) NSRegularExpression *quoteRegex;

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
		if (err)
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.rmdEquationRegex = [NSRegularExpression regularExpressionWithPattern:@"\\$\\$?(.*?)\\$\\$?"
																		  options:NSRegularExpressionDotMatchesLineSeparators error:&err];
		if (err)
			Rc2LogError(@"error compiling rmd chunk regex: %@", err);
		self.codeHighlighter = [[RCCodeHighlighterR alloc] init];
	}
	return self;
}

-(void)performSetup
{
	[super performSetup];
	self.codeHighlighter.colorMap = self.colorMap;
	self.docHighlighter.colorMap = self.colorMap;
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
	}
//	[self adjustParseRanges:chunks fullRange:range];
	[self colorChunks:chunks];
}

@end
