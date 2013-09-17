//
//  RCSyntaxParser.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCCodeHighlighter.h"

@class RCChunk;
@class Rc2FileType;

extern NSString *kChunkStartAttribute;


@interface RCSyntaxParser : NSObject
@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, copy) NSDictionary *colorMap;
@property (nonatomic, strong) id<RCCodeHighlighter> docHighlighter;
@property (nonatomic, strong) id<RCCodeHighlighter> codeHighlighter;

+(instancetype)parserWithTextStorage:(NSTextStorage*)storage fileType:(Rc2FileType*)fileType;

-(void)parse;
-(void)parseRange:(NSRange)range;
-(void)syntaxHighlightChunksInRange:(NSRange)range;

//returns the chunk of the first character
-(RCChunk*)chunkForRange:(NSRange)range;
//returns all chunks in range
-(NSArray*)chunksForRange:(NSRange)range;

//for subclasses to run post-init code
-(void)performSetup;

//for subclasses to call

//highlights the syntax in chunkArray
-(void)colorChunks:(NSArray*)chunkArray;
//sets the parseRange property for the chunks
-(void)adjustParseRanges:(NSArray*)chunkArray fullRange:(NSRange)fullRange;
@end
