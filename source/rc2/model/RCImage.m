//
//  RCImage.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCImage.h"

@implementation RCImage

-(id)initWithPath:(NSString*)aPath
{
	static NSInteger sNextFileId=-1;
	self = [super init];
	self.path = aPath;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	self.image = [[NSImage alloc] initWithContentsOfFile:aPath];
#else
	UIImage *img = [[UIImage alloc] initWithContentsOfFile:aPath];
	self.image = img;
#endif
	self.timestamp = [NSDate timeIntervalSinceReferenceDate];
	NSString *pathc = aPath.lastPathComponent;
	if (![pathc containsCharacterNotInSet:[NSCharacterSet decimalDigitCharacterSet]])
		self.imageId = [NSNumber numberWithInt:[pathc intValue]];
	else
		self.imageId = [NSNumber numberWithInteger:sNextFileId--];
	self.name = pathc;
	return self;
}

-(void)setName:(NSString *)name
{
	_name = [name copy];
}
@end
