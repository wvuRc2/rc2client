//
//  RCImage.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCImage.h"

@implementation RCImage
@synthesize name;
@synthesize path;
@synthesize image;
@synthesize timestamp;
@synthesize imageId;

-(id)initWithPath:(NSString*)aPath
{
	self = [super init];
	self.path = aPath;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	self.image = [[NSImage alloc] initWithContentsOfFile:aPath];
#else
	UIImage *img = [[UIImage alloc] initWithContentsOfFile:aPath];
	self.image = img;
#endif
	self.timestamp = [NSDate timeIntervalSinceReferenceDate];
	return self;
}
@end
