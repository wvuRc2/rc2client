//
//  RCChunk.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCChunk.h"

@interface RCChunk()
@property (assign, readwrite) NSInteger chunkNumber;
@end

@implementation RCChunk

+(instancetype)documentationChunkWithNumber:(NSInteger)num
{
	RCChunk *c = [[RCChunk alloc] init];
	c.chunkType = eChunkType_Document;
	c.chunkNumber = num;
	return c;
}

+(instancetype)codeChunkWithNumber:(NSInteger)num name:(NSString*)aName;
{
	RCChunk *c = [[RCChunk alloc] init];
	c.chunkType = eChunkType_RCode;
	c.chunkNumber = num;
	c.name = aName;
	return c;
}

+(instancetype)equationWithNumber:(NSInteger)num type:(RCChunkEquationType)eqType
{
	RCChunk *c = [[RCChunk alloc] init];
	c.chunkType = eChunkType_Equation;
	c.chunkNumber = num;
	c.equationType = eqType;
	return c;
}

-(NSString*)description
{
	switch (self.chunkType) {
		case eChunkType_RCode:
			return [NSString stringWithFormat:@"R chunk %d \"%@\"", (int32_t)self.chunkNumber, self.name ? self.name : @"anonymous"];
		case eChunkType_Equation:
			return [NSString stringWithFormat:@"%@ equation chunk %d", self.equationDescription, (int32_t)self.chunkNumber];
		case eChunkType_Document:
		default:
			return [NSString stringWithFormat:@"documentation chunk %d", (int32_t)self.chunkNumber];
	}
}

-(NSString*)equationDescription
{
	switch(self.equationType) {
		case eChunkEquationType_NotAnEquation:
		default:
			return @"";
		case eChunkEquationType_Inline:
			return @"inline";
		case eChunkEquationType_Display:
			return @"display";
		case eChunkEquationType_MathML:
			return @"MathML";
	}
}

@end
