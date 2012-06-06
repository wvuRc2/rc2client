//
//  RCImageCache.m
//  MacClient
//
//  Created by Mark Lilback on 3/9/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCImageCache.h"
#import "RCImage.h"
#import "RCFile.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

@interface RCImageCache()
@property (nonatomic, strong) NSString *imgCachePath;
@property (nonatomic, strong) NSMutableDictionary *metaData;
@property (nonatomic, strong) NSMutableDictionary *imgCache; //key is string of image id (or path if from an RCFile)
@property (nonatomic, strong) NSOperationQueue *dloadQueue;
@end

#define kPref_ImageMetaData @"ImageMetaData"

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
		self.imgCache = [NSMutableDictionary dictionary];
		self.dloadQueue = [[NSOperationQueue alloc] init];
		self.metaData = [[[NSUserDefaults standardUserDefaults] objectForKey:kPref_ImageMetaData] mutableCopy];
		//FIXME: we used to keep numbers in here. this can be removed mid-June as both Jim and I will be using strings
		if ([self.metaData.allKeys.firstObject isKindOfClass:[NSNumber class]])
			[self.metaData removeAllObjects];
	}
	return self;
}

-(void)saveFileName:(NSString*)fname forId:(NSString*)imageIdStr
{
	[self.metaData setObject:fname forKey:imageIdStr];
	[[NSUserDefaults standardUserDefaults] setObject:self.metaData forKey:kPref_ImageMetaData];
}

-(void)clearCache
{
	[self.metaData removeAllObjects];
	[[NSUserDefaults standardUserDefaults] setObject:self.metaData forKey:kPref_ImageMetaData];
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSError *err=nil;
	for (NSString *fname in [fm contentsOfDirectoryAtPath:self.imgCachePath error:nil]) {
		NSString *path = [self.imgCachePath stringByAppendingPathComponent:fname];
		if ([path hasSuffix:@"png"] || [path hasSuffix:@"pdf"])
			if (![fm removeItemAtPath:path error:&err])
				Rc2LogError(@"error removing %@ from cache", path);
	}
}

-(NSArray*)allImages
{
	return [self.imgCache allValues];
}

-(RCImage*)loadImageIntoCache:(NSString*)imageIdStr
{
	NSString *imgPath = imageIdStr;
	if (![imgPath hasSuffix:@".png"])
		imgPath = [imgPath stringByAppendingPathExtension:@"png"];
	NSString *fpath = [self.imgCachePath stringByAppendingPathComponent:imgPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fpath])
		return nil;
	RCImage *img = [[RCImage alloc] initWithPath:fpath];
	NSString *cachedName = [self.metaData objectForKey:img.imageId.description];
	if (cachedName)
		img.name = cachedName;
	[self.imgCache setObject:img forKey:imageIdStr];
	return img;
}

-(RCImage*)loadImageFileIntoCache:(RCFile*)file
{
	RCImage *img = [[RCImage alloc] initWithPath:file.fileContentsPath];
	img.name = file.name;
	[self.imgCache setObject:img forKey:img.imageId.description];
	return img;
}

-(void)cacheImagesReferencedInHTML:(NSString*)html
{
	if (nil == html)
		return;
	NSError *err=nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"rc2img:///([0-9]+).png" options:0 error:&err];
	ZAssert(nil == err, @"error compiling regex: %@", [err localizedDescription]);
	[regex enumerateMatchesInString:html options:0 range:NSMakeRange(0, [html length]) 
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) 
	 {
		 NSString *fname = [html substringWithRange:[match rangeAtIndex:1]];
		 [[RCImageCache sharedInstance] loadImageIntoCache:fname];
	 }];
}


-(void)cacheImages:(NSArray*)imgDicts
{
	for (NSDictionary *imgDict in imgDicts) {
		NSString *fname = [imgDict objectForKey:@"name"];
		NSString *imgPath = [self.imgCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", 
																			   [imgDict objectForKey:@"id"]]];
		NSString *urlStr = [imgDict objectForKey:@"url"];
		if ([urlStr characterAtIndex:0] == '/')
			urlStr = [urlStr substringFromIndex:1];
		urlStr = [urlStr stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
		urlStr = [[Rc2Server sharedInstance].baseUrl stringByAppendingString:urlStr];
		NSURL *url = [NSURL URLWithString:urlStr];
		ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithURL:url];
		[req setDownloadDestinationPath: imgPath];
		[req setCompletionBlock:^{
			RCImage *img = [[RCImage alloc] initWithPath:imgPath];
			img.name = fname;
			img.imageId = [imgDict objectForKey:@"id"];
			if ([img.name indexOf:@"#"] != NSNotFound)
				img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
			[[[RCImageCache sharedInstance] imgCache] setObject:img forKey:img.imageId.description];
			[[RCImageCache sharedInstance] saveFileName:img.name forId:img.imageId.description];
		}];
		[self.dloadQueue addOperation:req];
	}
}

-(NSArray*)adjustImageArray:(NSArray*)inArray
{
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	for (NSDictionary *imgDict in inArray) {
		[outArray addObject:[NSString stringWithFormat:@"rc2img:///%@.png", [imgDict objectForKey:@"id"]]];
	}
	[self cacheImages:inArray];
	return outArray;
}

-(RCImage*)imageWithId:(NSString*)imgId
{
	return [self.imgCache objectForKey:imgId];
}

@synthesize imgCache=_imgCache;
@synthesize imgCachePath=_imgCachePath;
@synthesize dloadQueue=_dloadQueue;
@synthesize metaData=_metaData;
@end
