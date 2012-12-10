//
//  RCFile.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_RCFile.h"
#import "RCFileContainer.h"

@class Rc2FileType;

@interface RCFile : _RCFile
@property (nonatomic, readonly) Rc2FileType *fileType;
@property (nonatomic, readonly) BOOL isTextFile;
@property (nonatomic, readonly) BOOL contentsLoaded; //not KVO compliant
@property (nonatomic, readonly) BOOL existsOnServer; //not KVO compliant
@property (nonatomic, readonly) BOOL locallyModified;
@property (weak, nonatomic, readonly) NSString *currentContents; //not KVO compliant
@property (nonatomic, strong) NSMutableDictionary *localAttrs;
@property (nonatomic, weak, readonly) id<RCFileContainer> container;

//parses an array of dictionaries sent from the server
+(NSArray*)filesFromJsonArray:(NSArray*)inArray container:(id<RCFileContainer>)container;

-(void)updateWithDictionary:(NSDictionary*)dict;

-(void)discardEdits;
-(void)updateContentsFromServer:(BasicBlock1IntArg)hblock; //fetches file contents if they are nil and is a text file. refetches binary file contents

//on iOS, returns UIImage. on Mac returns NSImage
-(id)fileIcon;

-(NSString*)fileContentsPath;

//on iOS, returns UIImage. on Mac returns NSImage
-(id)permissionImage;

@end
