//
//  RCDropboxSync.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/21/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCDropboxSync.h"
#import "RCWorkspace.h"
#import "DropBlocks.h"

@interface RCDropboxSync ()
@property (nonatomic, strong) RCWorkspace *wspace;
@end

@implementation RCDropboxSync

-(id)initWithWorkspace:(RCWorkspace *)wspace
{
	if ((self = [super init])) {
		self.wspace = wspace;
	}
	return self;
}

-(void)startSync
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *dbpath = self.wspace.dropboxPath;
		ZAssert(dbpath, @"workspace not configured for sync");
		if (nil == self.wspace.dropboxHash) {
			[self doFirstSync];
		}  else {
			[self doRegularSync];
		}
	});
}

-(void)doFirstSync
{
	[DropBlocks loadMetadata:self.wspace.dropboxPath completionBlock:^(DBMetadata *metadata, NSError *error) {
		NSLog(@"md=%@", metadata);
	}];
	if (self.completionHandler)
		self.completionHandler(NO, [NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"first time sync not implemented"}]);
}

-(void)doRegularSync
{
	if (self.completionHandler)
		self.completionHandler(NO, [NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"regular sync not implemented"}]);
}

@end
