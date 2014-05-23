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
		self.name = [dict objectForKeyWithNullAsNil:@"name"];
		self.dropboxUser = [dict objectForKeyWithNullAsNil:@"dbuser"];
		self.dropboxPath = [dict objectForKeyWithNullAsNil:@"dbpath"];
		self.dropboxHash = [dict objectForKeyWithNullAsNil:@"dbhash"];
		self.dropboxHistory = [dict objectForKeyWithNullAsNil:@"dbhistory"];
		self.shared = [[dict objectForKeyWithNullAsNil:@"shared"] boolValue];
		
		self.wspaceId = [dict objectForKey:@"id"];
		NSNumber *ladate = [dict objectForKey:@"lastaccess"];
		self.lastAccess = [NSDate dateWithTimeIntervalSince1970:[ladate longLongValue]/1000];
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
		RCWorkspaceCache *cache = [RCWorkspaceCache MR_findFirstByAttribute:@"wspaceId" withValue:self.wspaceId];
		if (nil == cache) {
			cache = [RCWorkspaceCache MR_createEntity];
			cache.wspaceId = self.wspaceId;
		}
		self.myCache = cache;
	}
	return self.myCache;
}

-(void)refreshFiles
{
	self.fetchingFiles = YES;
	[[Rc2Server sharedInstance] refereshWorkspace:self completionHandler:^(BOOL success, id results) {
		if (success && [[results objectForKey:@"status"] integerValue] == 0) {
			NSDictionary *d = [results objectForKey:@"wspace"];
			self.name = [d objectForKey:@"name"];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.files = [RCFile filesFromJsonArray:[d objectForKey:@"files"] container:self];
				self.fetchingFiles = NO;
				[[NSNotificationCenter defaultCenter] postNotificationName:RCFileContainerChangedNotification object:nil];
			});
		}
	}];
}

-(RCFile*)updateFileId:(NSNumber*)fileId
{
	RCFile *file = [self fileWithId:fileId];
	if (file) {
		//FIXME: this doesn't update metadata
		[file updateContentsFromServer:^(NSInteger success){}];
	} else {
		//FIXME: for now, we're just refreshing them all
		[self refreshFiles];
	}
	return file;
}

-(NSComparisonResult)compareWithItem:(RCWorkspace*)anItem
{
	ZAssert(![self.name isKindOfClass:[NSNull class]], @"my name is null");
	ZAssert(![anItem.name isKindOfClass:[NSNull class]], @"your name is null");
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
	for (RCFile *aFile in self.project.files) {
		if ([fileId isEqualToNumber:aFile.fileId])
			return aFile;
	}
	return nil;
}

-(RCFile*)fileWithName:(NSString*)fileName
{
	for (RCFile *aFile in self.files) {
		if (NSOrderedSame == [fileName caseInsensitiveCompare:aFile.name])
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
	[aFile setValue:self forKey:@"container"];
	ZAssert(aFile.container == self, @"not set as container");
	[[NSNotificationCenter defaultCenter] postNotificationName:RCFileContainerChangedNotification object:self];
}

-(void)removeFile:(RCFile*)aFile
{
	[aFile.managedObjectContext deleteObject:aFile];
	NSInteger idx = [_files indexOfObject:aFile];
	if (idx != NSNotFound)
		self.files = [_files arrayByRemovingObjectAtIndex:idx];
}

-(NSString*)fileCachePath
{
	if (nil == self.fspath) {
		self.fspath = [[self.project fileCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"ws%@", self.wspaceId]];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *err=nil;
		if (![fm fileExistsAtPath:_fspath])
			if (![fm createDirectoryAtPath:_fspath withIntermediateDirectories:YES attributes:nil error:nil])
				Rc2LogError(@"failed to create workspace directory:%@", err);
	}
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

-(id)debugQuickLookObject
{
	return [NSString stringWithFormat:@"RCWorkspace: %@(%@)", self.name, self.wspaceId];
}

@end
