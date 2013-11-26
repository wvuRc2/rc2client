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
#import "Rc2AppConstants.h"

@interface RCSweaveParser ()
@property (nonatomic, strong) NSRegularExpression *startExpression;
@property (nonatomic, copy) NSArray *myChunks;
@end

@implementation RCSweaveParser

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
		self.docHighlighter = [[RCCodeHighlighterLatex alloc] init];
	}
	return self;
}

-(void)performSetup
{
	[super performSetup];
	self.codeHighlighter.colorMap = self.colorMap;
	self.docHighlighter.colorMap = self.colorMap;
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
		 newChunk.contentOffset = result.range.length + 1;
//		 NSLog(@"chunk at %@", NSStringFromRange(result.range));
		 [chunkArray addObject:newChunk];
	 }];
	[self adjustParseRanges:chunkArray fullRange:fullRange];
	[self colorChunks:chunkArray];
	self.myChunks = chunkArray;
}

-(NSArray*)chunks
{
	return _myChunks;
}

@end
