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

-(id)initWithPath:(NSString*)aPath
{
	self = [super init];
	self.path = aPath;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	self.image = [[[NSImage alloc] initWithContentsOfFile:aPath] autorelease];
#else
	self.image = [UIImage imageWithContentsOfFile:aPath];
#endif
	self.timestamp = [NSDate timeIntervalSinceReferenceDate];
	return self;
}
@end
