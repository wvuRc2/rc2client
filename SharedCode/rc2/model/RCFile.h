//
//  RCFile.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_RCFile.h"

@interface RCFile : _RCFile
@property (nonatomic, readonly) BOOL isTextFile;
@property (nonatomic, readonly) BOOL contentsLoaded; //not KVO compliant
@property (nonatomic, readonly) BOOL existsOnServer; //not KVO compliant
@property (nonatomic, readonly) NSString *currentContents; //not KVO compliant

//parses an array of dictionaries sent from the server
+(NSArray*)filesFromJsonArray:(NSArray*)inArray;

-(void)updateWithDictionary:(NSDictionary*)dict;

-(void)discardEdits;

//on iOS, returns UIImage. on Mac returns NSImage
-(id)fileIcon;

//currently only implemented for Mac
-(NSString*)fileContentsPath;
@end
