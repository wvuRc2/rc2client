//
//  RCSyntaxParser.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCSyntaxParser.h"
#import "AppConstants.h"
#import "RCChunk.h"
#import "Rc2FileType.h"
#import "RCSweaveParser.h"
#import "RCHighlightingParser.h"
#import "RCRmdParser.h"
#import "RCCodeHighlighterR.h"
#import "RCCodeHighlighterSas.h"

#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#define ColorClass NSColor
#else
#define ColorClass UIColor
#endif

@interface RCSyntaxParser ()
@property (nonatomic, copy) NSString *lastSource;
@end

NSString *kChunkStartAttribute = @"RCChunkStart";

@implementation RCSyntaxParser

+(instancetype)parserWithTextStorage:(NSTextStorage*)storage fileType:(Rc2FileType*)fileType
{
	Class highClass = nil;
	Class theClass = nil;
	if (fileType.isSweave)
		theClass = [RCSweaveParser class];
	else if ([fileType.extension isEqualToString:@"Rmd"])
		theClass = [RCRmdParser class];
	else if ([fileType.extension isEqualToString:@"R"]) {
		theClass = [RCHighlightingParser class];
		highClass = [RCCodeHighlighterR class];
	} else if ([fileType.extension isEqualToString:@"sas"]) {
		theClass = [RCHighlightingParser class];
		highClass = [RCCodeHighlighterSas class];
	}
	RCSyntaxParser *p = [[theClass alloc] init];
	p.textStorage = storage;
	p.colorMap = [RCSyntaxParser syntaxColors];
	if (highClass)
		p.codeHighlighter = [[highClass alloc] init];
	[p performSetup];
	return p;
}

+(NSDictionary*)syntaxColors
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *colors = [NSMutableDictionary dictionaryWithCapacity:6];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Comment]] forKey:kPref_SyntaxColor_Comment];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Function]] forKey:kPref_SyntaxColor_Function];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Keyword]] forKey:kPref_SyntaxColor_Keyword];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Quote]] forKey:kPref_SyntaxColor_Quote];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_Symbol]] forKey:kPref_SyntaxColor_Symbol];
	[colors setObject:[ColorClass colorWithHexString:[defs objectForKey:kPref_SyntaxColor_CodeBackground]] forKey:kPref_SyntaxColor_CodeBackground];
	return colors;
}

- (id)init
{
	if ((self = [super init])) {
		if (nil == self.colorMap)
			self.colorMap = [RCSyntaxParser syntaxColors];
	}
	return self;
}

-(RCChunk*)chunkForRange:(NSRange)range
{
	NSAttributedString *string = self.textStorage;
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

-(NSArray*)chunksForRange:(NSRange)range
{
	__block NSMutableArray *outArray = [NSMutableArray array];
	[self.textStorage enumerateAttribute:kChunkStartAttribute inRange:range options:0 usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		[outArray addObject:value];
	}];
	return outArray;
}

-(void)parse
{
	if (![self.textStorage.string isEqualToString:self.lastSource]) {
		[self parseRange:NSMakeRange(0, self.textStorage.length)];
		self.lastSource = self.textStorage.string;
	}
}

-(void)parseRange:(NSRange)range
{
	NSAssert(NO, @"feature not implemented");
}

-(void)syntaxHighlightChunksInRange:(NSRange)range
{
	NSArray *chunks = [self chunksForRange:range];
	[self colorChunks:chunks];
}

-(void)performSetup
{
	
}

//sets the parseRange property for the chunks
-(void)adjustParseRanges:(NSArray*)chunkArray fullRange:(NSRange)fullRange
{
	//iterate array to adjust the content array
	NSUInteger curChunkIndex=0;
	NSUInteger numChunks = chunkArray.count;
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
	finalRange.length = fullRange.length - finalRange.location;
	[[chunkArray lastObject] setParseRange:finalRange];
}

-(void)colorChunks:(NSArray*)chunkArray
{
	for (RCChunk *aChunk in chunkArray) {
		[self.textStorage addAttribute:kChunkStartAttribute value:aChunk range:aChunk.parseRange];
		if (aChunk.chunkType == eChunkType_RCode) {
			id bgc = [self.colorMap objectForKey:kPref_SyntaxColor_CodeBackground];
			if (bgc)
				[self.textStorage addAttribute:NSBackgroundColorAttributeName value:bgc range:aChunk.parseRange];
			[self.codeHighlighter highlightText:self.textStorage range:aChunk.parseRange];
		} else if (aChunk.chunkType == eChunkType_Document) {
			[self.docHighlighter highlightText:self.textStorage range:aChunk.parseRange];
		}
	}
	
}

-(void)setCodeHighlighter:(id<RCCodeHighlighter>)codeHighlighter
{
	_codeHighlighter = codeHighlighter;
	_codeHighlighter.colorMap = self.colorMap;
}
@end
