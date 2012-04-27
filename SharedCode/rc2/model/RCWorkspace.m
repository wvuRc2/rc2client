//
//  RCWorkspace.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "RCWorkspace.h"
#import "Rc2Server.h"
#import "RCFile.h"
#import "RCWorkspaceShare.h"
#import "RCWorkspaceCache.h"
#import "ASIFormDataRequest.h"

NSString * const RCWorkspaceFilesFetchedNotification = @"RCWorkspaceFilesFetchedNotification";

@interface RCWorkspace()
@property (nonatomic, copy, readwrite) NSArray *files;
@property (nonatomic, readwrite) BOOL sharedByOther;
@property (nonatomic, strong) RCWorkspaceCache *myCache;
@property (assign) BOOL fetchingFiles;
@property (assign) BOOL fetchingShares;
@end

@implementation RCWorkspace
@synthesize files=_files;
@synthesize fetchingFiles;
@synthesize fetchingShares;
@synthesize shares;
@synthesize sharedByOther;
@synthesize myCache;
@synthesize updateFileContentsOnNextFetch;

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super initWithDictionary:dict])) {
		self.shares = [NSMutableArray array];
		self.sharedByOther = [[dict objectForKey:@"shared"] boolValue];
	}
	return self;
}

- (void)dealloc
{
	[self removeAllBlockObservers];
}

-(RCWorkspaceCache*)cache
{
	if (nil == self.myCache) {
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		RCWorkspaceCache *cache = [[moc fetchObjectsForEntityName:@"WorkspaceCache" 
													withPredicate:@"wspaceId = %@", self.wspaceId] anyObject];
		if (nil == cache) {
			cache = [RCWorkspaceCache insertInManagedObjectContext:moc];
			cache.wspaceId = self.wspaceId;
		}
		self.myCache = cache;
	}
	return self.myCache;
}

-(void)refreshFiles
{
	[self refreshFilesPerformingBlockBeforeNotification:^{}];
}

-(void)refreshFilesPerformingBlockBeforeNotification:(BasicBlock)block
{
	self.fetchingFiles=YES;
	[[Rc2Server sharedInstance] fetchFileList:self completionHandler:^(BOOL success, id results) {
		if (success && [results isKindOfClass:[NSArray class]]) {
			self.files = [RCFile filesFromJsonArray:results];
			if (self.updateFileContentsOnNextFetch) {
				for (RCFile *file in self.files)
					[file updateContentsFromServer];
				self.updateFileContentsOnNextFetch=NO;
			}
			block();
			[[NSNotificationCenter defaultCenter] postNotificationName:RCWorkspaceFilesFetchedNotification object:self];
		}
		self.fetchingFiles=NO;
	}];
}

-(void)refreshShares
{
	self.fetchingShares=YES;
	[[Rc2Server sharedInstance] fetchWorkspaceShares:self completionHandler:^(BOOL success, id results) {
		self.fetchingShares=NO;
		[self willChangeValueForKey:@"shares"];
		[self didChangeValueForKey:@"shares"];
	}];
}

-(void)updateShare:(RCWorkspaceShare*)share permission:(NSString*)perm
{
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:
						   [NSString stringWithFormat:@"workspace/%@/share/%@", self.wspaceId, share.shareId]];
	req.requestMethod = @"PUT";
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:share.requiresOwner], @"requiresOwner",
						  [NSNumber numberWithBool:share.canOpenFiles], @"canOpenFiles",
						  [NSNumber numberWithBool:share.canWriteFiles], @"canWriteFiles",
						  nil];
	[req appendPostData:[[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req startSynchronous];
}

-(void)updateFileId:(NSNumber*)fileId
{
	//FIXME: for now, we're just refreshing them all
	[self refreshFiles];
}

-(RCWorkspaceShare*)shareForUserId:(NSNumber*)userId
{
	for (RCWorkspaceShare *share in self.shares) {
		if ([share.userId isEqual:userId])
			return share;
	}
	return nil;
}

-(BOOL)canDelete
{
	if (self.sharedByOther)
		return NO;
	if ([self.name isEqualToString:@"default"])
		return NO;
	return YES;
}

-(NSArray*)files
{
	if (nil == _files && !self.fetchingFiles)
		[self refreshFiles];
	return _files;
}

-(void)setFiles:(NSArray*)anArray
{
	if ([anArray isEqual:_files])
		return;
	_files = [anArray copy];
}

-(RCFile*)fileWithId:(NSNumber*)fileId
{
	for (RCFile *aFile in self.files) {
		if ([fileId isEqualToNumber:aFile.fileId])
			return aFile;
	}
	return nil;
}

-(RCFile*)fileWithName:(NSString*)fileName
{
	for (RCFile *aFile in self.files) {
		if ([fileName isEqualToString:aFile.name])
			return aFile;
	}
	return nil;
}

-(void)addFile:(RCFile *)aFile
{
	if ([_files containsObject:aFile])
		return;
	if (nil == _files)
		self.files = [NSArray arrayWithObject:aFile];
	else
		self.files = [_files arrayByAddingObject:aFile];
}

@end
