//
//  RCImageCache.m
//  MacClient
//
//  Created by Mark Lilback on 3/9/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

/*	metaData stores file ids mapped to file names that were user edited.
 	Also stores img groups using groupname as key, array of image ids as value. These are in the groups dict
 */

#import "RCImageCache.h"
#import "RCImage.h"
#import "RCFile.h"
#import "Rc2Server.h"

@interface RCImageCache()
@property (nonatomic, strong, readwrite) NSString *imgCachePath;
@property (nonatomic, strong) NSFetchRequest *allImageFetchRequest;
@property (atomic) BOOL ignoreLoadNotification;
@end

NSString *const kPref_ImageMetaData = @"ImageMetaData";

@implementation RCImageCache

+(id)sharedInstance
{
	static RCImageCache *sInstance=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sInstance = [[RCImageCache alloc] init];
	});
	return sInstance;
}

- (id)init
{
	if ((self = [super init])) {
		NSError *err=nil;
		NSFileManager *fm = [[NSFileManager alloc] init];
		NSURL *cacheUrl = [fm URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask
							appropriateForURL:nil create:YES error:&err];
		cacheUrl = [cacheUrl URLByAppendingPathComponent:@"Rc2/Rimages"];
		if (![fm fileExistsAtPath:cacheUrl.path]) {
			BOOL result = [fm createDirectoryAtPath:[cacheUrl path]
						withIntermediateDirectories:YES
										 attributes:nil
											  error:&err];
			ZAssert(result, @"failed to create img cache directory: %@", [err localizedDescription]);
		}
		self.imgCachePath = [cacheUrl path];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadImageFromFile:) name:RCImageLoadingNeededNotification object:nil];
		NSFetchRequest *freq = [[NSFetchRequest alloc]initWithEntityName:[RCImage entityName]];
		freq.fetchLimit = 20;
		freq.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:RCImageAttributes.timestamp ascending:YES]];
		self.allImageFetchRequest = freq;
	}
	return self;
}

-(void)loadImageFromNetwork:(RCImage*)image
{
	NSString *imgPath = [self.imgCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", image.imageId]];
	NSString *urlStr = [NSString stringWithFormat:@"/simg/%@.png", image.imageId];
	__weak RCImage *weakImage = image;
	[RC2_SharedInstance() downloadAppPath:urlStr toFilePath:imgPath completionHandler:^(BOOL success, id rsp) {
		if (success) {
			weakImage.image = [[ImageClass alloc] initWithContentsOfFile:imgPath];
		} else {
			Rc2LogWarn(@"loadImageFromNetwork: rcved a %@ for %@", rsp, urlStr);
		}
	}];
}

-(void)loadImageFromFile:(NSNotification*)note
{
	if (self.ignoreLoadNotification)
		return;
	self.ignoreLoadNotification = YES;
	RCImage *image = note.object;
	NSString *imgPath = [self.imgCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", image.imageId]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
		image.image = [[ImageClass alloc] initWithContentsOfFile:imgPath];
		if (image.image) {
			self.ignoreLoadNotification = NO;
			return;
		}
		//delete that file since isn't a valid image
		[[NSFileManager defaultManager] removeItemAtPath:imgPath error:nil];
	}
	self.ignoreLoadNotification = NO;
	[self loadImageFromNetwork:image];
}

-(NSArray*)allImages
{
	NSError *err;
	NSArray *images = [[NSManagedObjectContext MR_defaultContext] executeFetchRequest:self.allImageFetchRequest error:&err];
	if (nil == images)
		Rc2LogError(@"failed fetch request for images:%@", err);
	return images;
}

//note: not chcking for duplicates because server will never send duplicates in an array
-(NSArray*)cacheImagesWithServerDicts:(NSArray*)imgDicts
{
	NSMutableArray *outImages = [NSMutableArray arrayWithCapacity:imgDicts.count];
	for (NSDictionary *imgDict in imgDicts) {
//		NSString *urlStr = [imgDict objectForKey:@"url"];
//		if ([urlStr characterAtIndex:0] == '/')
//			urlStr = [urlStr substringFromIndex:1];
		RCImage *anImage = [RCImage MR_createEntity];
		anImage.name = imgDict[@"name"];
		anImage.imageId = imgDict[@"id"];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1070)
		[anImage image]; //force network loading
#endif
	}
	return outImages;
}

-(RCImage*)imageWithId:(NSInteger)imageId
{
	RCImage *img = [RCImage MR_findFirstByAttribute:@"imageId" withValue:@(imageId)];
	//TODO: if not found (is that possible?) should fetch from server
	if (nil == img)
		Rc2LogWarn(@"failed to find image:%ld", (long)imageId);
	return img;
}
@end
