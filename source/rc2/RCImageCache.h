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

@property (nonatomic, strong, readonly) NSString *imgCachePath;
@property (nonatomic, readonly) NSArray *allImages;

-(NSArray*)cacheImagesWithServerDicts:(NSArray*)imgDicts; //json dicts from server

-(RCImage*)imageWithId:(NSInteger)imgId;
@end
