//
//  RCImageCache.h
//  MacClient
//
//  Created by Mark Lilback on 3/9/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCImage;

@interface RCImageCache : NSObject
+(id)sharedInstance;
-(BOOL)loadImageIntoCache:(NSString*)imageId;
-(void)cacheImagesReferencedInHTML:(NSString*)html;
-(void)cacheImages:(NSArray*)imgDicts; //json dicts from server
-(NSArray*)allImages;
-(NSArray*)adjustImageArray:(NSArray*)inArray;
-(RCImage*)imageWithId:(NSString*)imgId;
@end
