//
//  RCImageCache.m
//  MacClient
//
//  Created by Mark Lilback on 3/9/12.
//  Copyright 2012 Agile Monks. All rights reserved.
//

#import "RCImageCache.h"
#import "RCImage.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

@interface RCImageCache()
@property (nonatomic, strong) NSString *imgCachePath;
@property (nonatomic, strong) NSMutableDictionary *imgCache;
@property (nonatomic, strong) NSOperationQueue *dloadQueue;
@end

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
		cacheUrl = [cacheUrl URLByAppendingPathComponent:@"Rimages"];
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
	}
	return self;
}

-(NSArray*)allImages
{
	return [self.imgCache allValues];
}

-(BOOL)loadImageIntoCache:(NSString*)imageId
{
	NSString *imgPath = [imageId stringByAppendingPathExtension:@"png"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *fpath = [self.imgCachePath stringByAppendingPathComponent:imgPath];
	if (![fm fileExistsAtPath:fpath])
		return NO;
	RCImage *img = [[RCImage alloc] initWithPath:fpath];
	img.name = [imgPath stringbyRemovingPercentEscapes];
	if ([img.name indexOf:@"#"] != NSNotFound)
		img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
	[self.imgCache setObject:img forKey:[imgPath stringByDeletingPathExtension]];
	return YES;
}

-(void)cacheImagesReferencedInHTML:(NSString*)html
{
	if (nil == html)
		return;
	NSError *err=nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"rc2img:///([0-9]+)" options:0 error:&err];
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
		}];
		[self.dloadQueue addOperation:req];
	}
}

-(NSArray*)adjustImageArray:(NSArray*)inArray
{
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	for (NSDictionary *imgDict in inArray) {
		[outArray addObject:[NSString stringWithFormat:@"rc2img:///%@", [imgDict objectForKey:@"id"]]];
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
@end
