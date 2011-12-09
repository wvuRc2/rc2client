//
//  RCImage.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCImage : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) NSTimeInterval timestamp;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@property (nonatomic, retain) NSImage *image;
#else
@property (nonatomic, strong) UIImage *image;
#endif

-(id)initWithPath:(NSString*)aPath;
@end
