//
//  RCImage.h
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "_RCImage.h"

extern NSString *const RCImageLoadingNeededNotification;

@interface RCImage : _RCImage
@property (nonatomic, strong) ImageClass *image;
@property (nonatomic, readonly) NSURL *fileUrl;
@end
