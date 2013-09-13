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
		self.codeHighlighter = [[RCCodeHighlighterR alloc] init];
		self.codeHighlighter.colorMap = self.colorMap;
		self.docHighlighter = [[RCCodeHighlighterLatex alloc] init];
		self.docHighlighter.colorMap = self.colorMap;
	}
	return self;
}

-(void)parseRange:(NSRange)fullRange
{
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
	[self adjustParseRanges:chunkArray fullRange:fullRange];
	[self colorChunks:chunkArray];
}


@end
