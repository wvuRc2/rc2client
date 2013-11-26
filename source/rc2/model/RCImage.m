//
//  RCImage.m
//
//  Created by Mark Lilback on 10/30/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "RCImage.h"
#import "RCImageCache.h"

@interface RCImage ()
@property (nonatomic, strong) NSCache *imgCache; //so the image object can be purged if memory is low
@property (atomic) BOOL isLoadingImage;
@end

NSString *const kImageKey = @"image";
NSString *const RCImageLoadingNeededNotification = @"RCImageLoadingNeededNotification";

@implementation RCImage

-(void)commonAwake
{
	self.imgCache = [[NSCache alloc] init];
}

-(void)awakeFromFetch
{
	[super awakeFromFetch];
	[self commonAwake];
}

-(void)awakeFromInsert
{
	[super awakeFromInsert];
	[self commonAwake];
	self.timestamp = [NSDate date];
}

-(ImageClass*)image
{
	ImageClass *img = [self.imgCache objectForKey:kImageKey];
	if (nil == img && !self.isLoadingImage) {
		///need to load from filesystem
		self.isLoadingImage = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:RCImageLoadingNeededNotification object:self];
		img = [self.imgCache objectForKey:kImageKey];
	}
	if (nil == img)
		return [ImageClass imageNamed:@"loading"];
	return img;
}

-(void)setImage:(ImageClass*)anImage
{
	if (nil == anImage)
		[self.imgCache removeObjectForKey:kImageKey];
	else
		[self.imgCache setObject:anImage forKey:kImageKey];
	self.isLoadingImage = NO;
}

-(NSString*)fullPath
{
	NSString *fname = [NSString stringWithFormat:@"%@.png", self.imageId];
	return [[[RCImageCache sharedInstance] imgCachePath] stringByAppendingPathComponent:fname];
}

-(NSURL*)fileUrl
{
	return [NSURL fileURLWithPath:[self fullPath]];
}

-(NSString*)debugDescription
{
	return [NSString stringWithFormat:@"RCImage %@(%@)", self.name, self.imageId];
}

@synthesize imgCache;
@synthesize isLoadingImage;
@end
