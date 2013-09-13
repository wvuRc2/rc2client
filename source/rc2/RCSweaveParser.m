//
//  RCSweaveParser.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCSweaveParser.h"
#import "RCChunk.h"
#import "RCCodeHighlighterR.h"
#import "RCCodeHighlighterLatex.h"
#import "AppConstants.h"

#define kChunkStartAttribute @"RCChunkStart"

#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#define ColorClass NSColor
#else
#define ColorClass UIColor
#endif


@interface RCSweaveParser ()
@property (nonatomic, strong) NSRegularExpression *startExpression;
@property (nonatomic, strong) RCCodeHighlighterR *rHighlighter;
@property (nonatomic, strong) RCCodeHighlighterLatex *latexHighlighter;
@end

@implementation RCSweaveParser

+(instancetype)parserWithTextStorage:(NSTextStorage*)storage
{
	RCSweaveParser *p = [[RCSweaveParser alloc] init];
	p.textStorage = storage;
	return p;
}

- (id)init
{
	if ((self = [super init])) {
		NSError *error;
		NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
		NSString *pattern = @"^(@(?!@))|(<<([^>]*)>>= ?.*?$)";
		NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
		
		self.startExpression = expression;
		NSAssert(self.startExpression, @"failed to get reg ex:%@", error);
		self.rHighlighter = [[RCCodeHighlighterR alloc] init];
		NSDictionary *colors = [self syntaxColors];
		self.rHighlighter.colorMap = colors;
		self.latexHighlighter = [[RCCodeHighlighterLatex alloc] init];
		self.latexHighlighter.colorMap = colors;
	}
	return self;
}

-(RCChunk*)chunkForString:(NSMutableAttributedString*)string range:(NSRange)range
{
	if (range.location == NSNotFound)
		return nil;
	if (range.location == 0 && range.length == 0) {
		if (string.length < 1)
			return nil;
		range = NSMakeRange(0, 1); //first chunk
	}
	if (range.location == string.length && range.length == 0)
		range.location -= 1;
	RCChunk *c = [string attribute:kChunkStartAttribute atIndex:range.location effectiveRange:nil];
	return c;
}

-(void)parse
{
	NSRange fullRange = NSMakeRange(0, self.textStorage.length);
	NSRange curRange = fullRange;
	NSString *str = self.textStorage.string;
	NSInteger numChunks = [self.startExpression numberOfMatchesInString:str options:0 range:fullRange];
	if (numChunks < 1)
		return; //no chunks
	NSMutableArray *chunkArray = [NSMutableArray arrayWithCapacity:numChunks];
	__block NSInteger curChunkIndex=0;
	//loop through all chunks storing array of ranges
	[self.startExpression
	 enumerateMatchesInString:str options:0 range:curRange
	 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		 RCChunk *newChunk;
		 if (curChunkIndex == 0) { //first chunk
			 if (result.range.location > 0) {
				 //we need to record the default font at start of file
				 newChunk = [RCChunk documentationChunkWithNumber:curChunkIndex++];
				 newChunk.parseRange = NSMakeRange(0, result.range.location);
				 [chunkArray addObject:newChunk];
			 }
		 }
		 if ([str characterAtIndex:result.range.location] == '@') {
			 newChunk = [RCChunk documentationChunkWithNumber:curChunkIndex++];
		 } else {
			 NSString *cname = [result rangeAtIndex:3].length > 0 ? [str substringWithRange:[result rangeAtIndex:3]] : nil;
			 newChunk = [RCChunk codeChunkWithNumber:curChunkIndex++ name:cname];
		 }
		 newChunk.parseRange = result.range;
//		 NSLog(@"chunk at %@", NSStringFromRange(result.range));
		 [chunkArray addObject:newChunk];
	 }];
	//iterate array to adjust the content array
	numChunks = chunkArray.count;
	for (curChunkIndex=0; curChunkIndex < numChunks-1; curChunkIndex++) {
		RCChunk *aChunk = [chunkArray objectAtIndex:curChunkIndex];
		RCChunk *nextChunk = [chunkArray objectAtIndex:curChunkIndex+1];
		NSRange rng = aChunk.parseRange;
		rng.length = nextChunk.parseRange.location - aChunk.parseRange.location;
		aChunk.parseRange = rng;
//		NSLog(@"adj chunk at %@", NSStringFromRange(rng));
	}
	//adjust final one
	NSRange finalRange = [[chunkArray lastObject] parseRange];
	finalRange.length = str.length - finalRange.location;
	[[chunkArray lastObject] setParseRange:finalRange];
	//now color them
	for (RCChunk *aChunk in chunkArray) {
		[self.textStorage addAttribute:kChunkStartAttribute value:aChunk range:aChunk.parseRange];
		if (aChunk.chunkType == eChunkType_RCode) {
			[self.rHighlighter highlightText:self.textStorage range:aChunk.parseRange];
		} else if (aChunk.chunkType == eChunkType_Document) {
			[self.latexHighlighter highlightText:self.textStorage range:aChunk.parseRange];
		}
	}
}

-(NSDictionary*)syntaxColors
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *colors = [NSMutableDictionary dictionaryWithCapacity:6];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Comment]] forKey:kPref_SyntaxColor_Comment];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Function]] forKey:kPref_SyntaxColor_Function];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Keyword]] forKey:kPref_SyntaxColor_Keyword];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Quote]] forKey:kPref_SyntaxColor_Quote];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Symbol]] forKey:kPref_SyntaxColor_Symbol];
	return colors;
}


@end
