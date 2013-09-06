//
//  RCImageCache.h
//  MacClient
//
//  Created by Mark Lilback on 3/9/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCImage;
@class RCFile;

@interface RCImageCache : NSObject
+(id)sharedInstance;

-(RCImage*)loadImageIntoCache:(NSString*)imageId;
-(RCImage*)loadImageFileIntoCache:(RCFile*)file;

-(void)cacheImagesReferencedInHTML:(NSString*)html;
-(void)cacheImages:(NSArray*)imgDicts; //json dicts from server
-(NSArray*)allImages;
-(NSArray*)adjustImageArray:(NSArray*)inArray;
-(RCImage*)imageWithId:(NSString*)imgId; //should be the number as a string
-(NSArray*)groupImagesForLinkPath:(NSString*)group;
-(void)clearCache;
@end
