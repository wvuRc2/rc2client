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
#import "RCProject.h"
#import "RCWorkspaceCache.h"
#import "ASIFormDataRequest.h"

@interface RCWorkspace()
@property (nonatomic, copy, readwrite) NSArray *files;
@property (nonatomic, strong) RCWorkspaceCache *myCache;
@property (assign) BOOL fetchingFiles;
@property (nonatomic, copy) NSString *fspath;
@end

@implementation RCWorkspace
@synthesize files=_files;

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.name = [dict objectForKey:@"name"];
		self.wspaceId = [dict objectForKey:@"id"];
		//this needs to run after init has returned so we'll have had our project set
		dispatch_async(dispatch_get_main_queue(), ^{
			self.files = [RCFile filesFromJsonArray:[dict objectForKey:@"files"] container:self];
		});
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
//	[self refreshFilesPerformingBlockBeforeNotification:^{}];
}
/*
-(void)refreshFilesPerformingBlockBeforeNotification:(BasicBlock)block
{
	//!FILECHANGE!
	
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
*/
-(void)updateFileId:(NSNumber*)fileId
{
	RCFile *file = [self fileWithId:fileId];
	if (file) {
		//FIXME: this doesn't update metadata
		[file updateContentsFromServer:^(NSInteger success){}];
	} else {
		//FIXME: for now, we're just refreshing them all
		[self refreshFiles];
	}
}

-(NSComparisonResult)compareWithItem:(RCWorkspace*)anItem
{
    return [self.name localizedStandardCompare: anItem.name];
}

-(BOOL)isFetchingFiles
{
	return self.fetchingFiles;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:RCFileContainerChangedNotification object:self];
}

-(void)removeFile:(RCFile*)aFile
{
	//TODO: implement
}

-(NSString*)fileCachePath
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		self.fspath = [[self.project fileCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"ws%@", self.wspaceId]];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *err=nil;
		if (![fm fileExistsAtPath:_fspath])
			if (![fm createDirectoryAtPath:_fspath withIntermediateDirectories:YES attributes:nil error:nil])
				Rc2LogError(@"failed to create workspace directory:%@", err);
	});
	return _fspath;
}

-(BOOL)userEditable
{
	//TODO: really implement
	return YES;
}

-(NSNumber*)projectId
{
	return self.project.projectId;
}

@end
