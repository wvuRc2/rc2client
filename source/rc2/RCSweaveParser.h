//
//  RCSweaveParser.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSTextStorage;
@class RCChunk;

@interface RCSweaveParser : NSObject
@property (nonatomic, strong) NSTextStorage *textStorage;

+(instancetype)parserWithTextStorage:(NSTextStorage*)storage;

-(void)parse;

-(RCChunk*)chunkForString:(NSMutableAttributedString*)string range:(NSRange)range;
@end
