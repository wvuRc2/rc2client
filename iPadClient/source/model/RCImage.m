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
	self.image = [UIImage imageWithContentsOfFile:aPath];
	self.timestamp = [NSDate timeIntervalSinceReferenceDate];
	return self;
}
@end
