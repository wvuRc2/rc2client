//
//  Rc2FileType.h
//  Rc2Client
//
//  Created by Mark Lilback on 8/29/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Rc2FileType : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *extension;
@property (nonatomic, readonly) NSString *details;
@property (nonatomic, readonly) NSString *iconName;
@property (readonly) BOOL isTextFile;
@property (readonly) BOOL isSourceFile;
@property (readonly) BOOL isImportable;
@property (readonly) BOOL isCreatable;
@property (readonly) BOOL isImage;
@property (readonly) id image; //always from a png
@property (readonly) id fileImage; //on mac, loads icon file or asks system for appropriate icon


+(NSArray*)allFileTypes;
+(Rc2FileType*)fileTypeWithExtension:(NSString*)fileExt;
+(NSArray*)imageFileTypes;
+(NSArray*)textFileTypes;
+(NSArray*)importableFileTypes;
+(NSArray*)creatableFileTypes;

@end
