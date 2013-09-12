//
//  RCChunk.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RCChunkType) {
	eChunkType_Document,
	eChunkType_RCode,
	eChunkType_Equation
};

typedef NS_ENUM(NSUInteger, RCChunkEquationType) {
	eChunkEquationType_NotAnEquation=0,
	eChunkEquationType_Inline,
	eChunkEquationType_Display,
	eChunkEquationType_MathML
};

@interface RCChunk : NSObject
@property (assign, readonly) NSInteger chunkNumber;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) RCChunkType chunkType;
@property (nonatomic, assign) RCChunkEquationType equationType;
//a private api used only by the parser/highlighter
@property (nonatomic) NSRange parseRange;

+(instancetype)documentationChunkWithNumber:(NSInteger)num;
+(instancetype)codeChunkWithNumber:(NSInteger)num name:(NSString*)aName;
+(instancetype)equationWithNumber:(NSInteger)num type:(RCChunkEquationType)eqType;
@end
