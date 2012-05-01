//
//  RCMCrashReportController.m
//  MacClient
//
//  Created by Mark Lilback on 5/1/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMCrashReportController.h"
#import "ASIFormDataRequest.h"
#import "Rc2Server.h"
#import <CrashReporter/CrashReporter.h>

@interface RCMCrashReportController()
@property (nonatomic, strong) IBOutlet NSArrayController *crController;
@end

@implementation RCMCrashReportController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.crController.content = [NSMutableArray array];
	[self verifyCacheData];
}

-(void)addReportToList:(NSData*)reportData
{
	NSError *err;
	PLCrashReport *rpt = [[PLCrashReport alloc] initWithData:reportData error:&err];
	if (nil == rpt) {
		Rc2LogError(@"error processing crash report:%@", err);
	} else {
		[self.crController addObject:rpt];
		NSString *strrpt = [PLCrashReportTextFormatter stringValueForCrashReport:rpt withTextFormat:PLCrashReportTextFormatiOS];
		NSLog(@"%@", strrpt);
	}
}

//should only be called on a background dispatch queue
-(void)processCrashList:(ASIHTTPRequest*)req
{
	if (req.responseStatusCode != 200) {
		[TheApp presentError:req.error];
		return;
	}
	NSString *cachePath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"crashreports/" ];
	NSArray *cids = [[req.responseString JSONValue] objectForKey:@"crashes"];
	for (NSNumber *cid in cids) {
		ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:[NSString stringWithFormat:@"crash/%@", cid]];
		[req startSynchronous];
		if (200 == req.responseStatusCode) {
			//save it
			NSString *path = [cachePath stringByAppendingPathComponent:[cid description]];
			[req.responseData writeToFile:path atomically:YES];
			[self performSelectorOnMainThread:@selector(addReportToList:) withObject:req.responseData waitUntilDone:NO];
		}
	}
}

-(void)verifyCacheData
{
	NSError *err;
	NSString *cachePath = [[TheApp thisApplicationsCacheFolder] stringByAppendingPathComponent:@"crashreports/" ];
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (![fm fileExistsAtPath:cachePath]) {
		if (![fm createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&err]) {
			Rc2LogError(@"failed to create crash report cache directory: %@", err);
			return;
		}
	}
	//get numerically sorted list of crash reports. filter out non digit file names (like .DS_Store)
	NSMutableArray *crlist = [[fm contentsOfDirectoryAtPath:cachePath error:&err] mutableCopy];
	[crlist filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF MATCHES '^\\\\d+'"]];
	[crlist sortUsingComparator:^(id obj1, id obj2) {
		return [obj1 compare:obj2 options:NSNumericSearch];
	}];
	int start = [[crlist lastObject] intValue];
	ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:[NSString stringWithFormat:@"crash?start=%d", start]];
	__block ASIHTTPRequest *req = theReq;
	[theReq setCompletionBlock:^{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self processCrashList:req];
		});
	}];
	[theReq startAsynchronous];
	//load data we already have
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		for (NSString *fname in crlist) {
			NSData *d = [NSData dataWithContentsOfFile:[cachePath stringByAppendingPathComponent:fname]];
			if (d)
				[self addReportToList:d];
		}
	});
}

@synthesize crController=_crController;
@end
