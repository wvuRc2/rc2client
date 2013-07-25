//
//  RCDropboxSync.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/21/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RCDropboxSync.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "Rc2Server.h"
#import "DropBlocks.h"
#import "RC2LoopQueue.h"

typedef NS_ENUM(NSUInteger, SyncState) {
	kCachingRc2Files,
	kLoadMetadata,
	kLoadRemoteFiles,
	kUploadingToRc2,
	kUploadingToDropbox,
	kLastMetaRefresh,
	kFinished
};

@interface RCDropboxSync () <DBRestClientDelegate>
@property (nonatomic, strong) RCWorkspace *wspace;
@property (nonatomic, strong) DBRestClient *client;
@property (nonatomic, strong) DBMetadata *metad;
@property (nonatomic, strong) NSMutableArray *dloadedFiles;
@property (nonatomic, copy) NSSet *vaildExtensions;
@property (nonatomic, copy) NSString *tmpPath;
@property (nonatomic, copy) NSArray *previousState;
@property (nonatomic, strong) NSFileManager *fm;
@property SyncState state;
@property NSUInteger curFileIdx;
@property NSUInteger filesDloadingFromRc2;
@property NSUInteger filesUploadingToDB;
@end

@implementation RCDropboxSync

-(id)initWithWorkspace:(RCWorkspace *)wspace
{
	if ((self = [super init])) {
		self.wspace = wspace;
		self.fm = [[NSFileManager alloc] init];
		self.tmpPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithUUID]];
		[_fm createDirectoryAtPath:self.tmpPath withIntermediateDirectories:YES attributes:nil error:nil];
		self.dloadedFiles = [NSMutableArray array];
		self.vaildExtensions = [NSSet setWithArray:[[Rc2Server acceptableImportFileSuffixes] arrayByPerformingSelector:@selector(lowercaseString)]];
	}
	return self;
}

-(void)dealloc
{
	[_fm removeItemAtPath:self.tmpPath error:nil];
}

-(NSString*)serializeFilesToJSON
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:self.wspace.files.count];
	//build a hash on filename to get dropbox rev values
	NSMutableDictionary *dbmd = [NSMutableDictionary dictionaryWithCapacity:self.metad.contents.count];
	for (DBMetadata *md in self.metad.contents)
		[dbmd setObject:md forKey:md.filename.lowercaseString];
	[self.wspace.files enumerateObjectsUsingBlock:^(RCFile *obj, NSUInteger idx, BOOL *stop) {
		NSString *rev = [[dbmd objectForKey:obj.name.lowercaseString] rev];
		if (nil == rev)
			rev = @"";
		ZAssert([obj name], @"file with no name");
		[a addObject:@{@"name":[obj name], @"lastMod":[NSNumber numberWithLongLong:obj.lastModified.timeIntervalSince1970 * 1000], @"filesize":obj.fileSize, @"dbrev":rev}];
	}];
	NSString *json = [a JSONRepresentation];
	ZAssert(json.length > 2, @"failed to serialize to json");
	return json;
}

-(void)startSync
{
	self.client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
	self.client.delegate = self;
	self.state = kCachingRc2Files;
	//make sure all files are cached locally
	for (RCFile *file in self.wspace.files) {
		if (![_fm fileExistsAtPath:file.fileContentsPath]) {
			_filesDloadingFromRc2++;
			[file updateContentsFromServer:^(NSInteger success) {
				if (success) {
					NSLog(@"cached %@", file.name);
					_filesDloadingFromRc2--;
				}
				if (_filesDloadingFromRc2 == 0)
					[self preflightComplete];
			}];
		}
	}
}

-(void)preflightComplete
{
	//dropbox only works on main thread
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *dbpath = self.wspace.dropboxPath;
		if (nil == dbpath) {
			[self.syncDelegate dbsync:self syncComplete:NO error:[NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"workspace not configured for sync"}]];
			return;
		}
		//load metadata
		self.state = kLoadMetadata;
		[_client loadMetadata:dbpath];
	});
}

-(void)loadedMetadata
{
	if (kLastMetaRefresh == self.state) {
		[self syncSuccessful];
	} else if (nil == self.wspace.dropboxHistory) {
		[self doFirstSync];
	}  else {
		[self doRegularSync];
	}
}

-(void)doFirstSync
{
	self.state = kLoadRemoteFiles;
	[self processNextDropboxFile];
}

-(void)doRegularSync
{
	self.previousState = [self.wspace.dropboxHistory JSONValue];
	ZAssert(self.previousState.count > 0, @"failed to parse sync history");
	//we have three lists of files (previousState, wspace.files, and metadata). Need to store based on filename
	NSMutableDictionary *history = [NSMutableDictionary dictionary];
	[self.previousState enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[history setObject:obj forKey:[obj objectForKey:@"name"]];
	}];
	NSMutableDictionary *dbox = [NSMutableDictionary dictionary];
	[self.metad.contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[dbox setObject:obj forKey:[obj filename]];
	}];
	NSMutableDictionary *wsfiles = [NSMutableDictionary dictionary];
	[self.wspace.files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[wsfiles setObject:obj forKey:[obj name]];
	}];
	NSMutableArray *addToDB = [NSMutableArray array];
	NSMutableArray *addToRc2 = [NSMutableArray array];
	NSMutableArray *deleteFromDB = [NSMutableArray array];
	//first, iterate through history files
	for (NSString *fname in history.allKeys) {
		NSDictionary *hitem = [history objectForKey:fname];
		NSDate *histMod = [NSDate dateWithTimeIntervalSince1970:[[hitem objectForKey:@"lastMod"] longLongValue] / 1000];
		RCFile *wsfile = [wsfiles objectForKey:fname];
		DBMetadata *filemd = [dbox objectForKey:fname];
		if (nil == wsfile) {
			//this file was deleted from workspace. We want to delete from dropbox unless dropbox rev is more recent than history
			if (![[hitem objectForKey:@"dbrev"] isEqualToString:filemd.rev]) {
				//the dbfile has changed. keep it
				[addToRc2 addObject:fname];
			} else {
				//want to delete from dropbox
				[deleteFromDB addObject:fname];
			}
		} else if (wsfile.lastModified.timeIntervalSince1970 > histMod.timeIntervalSince1970) {
			[addToDB addObject:wsfile];
		}
		if (nil == filemd) {
			//either need to add or delete from rc2
			if (wsfile)
				[addToDB addObject:wsfile];
			else {
				//not in db or rc2. guess that counts as deletion
			}
		} else if (![[hitem objectForKey:@"dbrev"] isEqualToString:filemd.rev]) {
			//TODO: handle change in poth`
			[addToRc2 addObject:fname];
		}
		//each loop we rmove files handled
		if (wsfile)
			[wsfiles removeObjectForKey:fname];
		if (filemd)
			[dbox removeObjectForKey:fname];
	}
	for (NSString *delfname in deleteFromDB) {
		Rc2LogInfo(@"deleting %@ from dropbox", delfname);
		[self.client deletePath:[self.wspace.dropboxPath stringByAppendingPathComponent:delfname]];
	}
	//need to load any new db files being uploaded to rc2
	if (addToRc2.count > 0) {
		RC2LoopQueue *dbuploadq = [[RC2LoopQueue alloc] initWithObjectArray:addToRc2 task:^(NSString *fname) {
			NSString *fpath = [_tmpPath stringByAppendingPathComponent:fname];
			if (![[NSFileManager defaultManager] fileExistsAtPath:fpath]) {
				__block NSCondition *dblock = [[NSCondition alloc] init];
				__block NSInteger dcnt=1;
				dispatch_sync(dispatch_get_main_queue(), ^{
					[DropBlocks loadFile:[self.wspace.dropboxPath stringByAppendingPathComponent:fname] intoPath:fpath
						 completionBlock:^(NSString *contentType, DBMetadata *metadata, NSError *error)
					 {
						 if (error) {
							 [self.syncDelegate dbsync:self syncComplete:NO error:error];
						 } else {
							 NSLog(@"downloaded %@ for upload to rc2", fname);
						 }
						 [dblock lock];
						 dcnt = 0;
						 [dblock signal];
						 [dblock unlock];
					 } progressBlock:^(CGFloat prog) {
						 
					 }];
				});
				[dblock lock];
				while (dcnt > 0)
					[dblock wait];
				[dblock unlock];
			}
		}];
		dbuploadq.completionHandler = ^(id foo) {
			[self regSyncPhase2:addToDB forRc2:addToRc2];
		};
		[dbuploadq startTasks];
	} else {
		[self regSyncPhase2:addToDB forRc2:addToRc2];
	}
}

-(void)regSyncPhase2:(NSMutableArray*)addToDB forRc2:(NSMutableArray*)addToRc2
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//add files to rc2
		for (NSString *rcfname in addToRc2) {
			Rc2LogInfo(@"adding %@ to rc", rcfname);
			NSURL *furl = [NSURL fileURLWithPath:[self.tmpPath stringByAppendingPathComponent:rcfname]];
			if (![[NSFileManager defaultManager] fileExistsAtPath:furl.path])
				Rc2LogError(@"db file isn't cached");
			NSError *err=nil;
			RCFile *efile = [self.wspace fileWithName:rcfname];
			if (efile.existsOnServer) {
				if ([[Rc2Server sharedInstance] updateFile:efile withContents:furl workspace:self.wspace error:&err]) {
					NSLog(@"uploaded %@ to rc2", rcfname);
				} else {
					NSLog(@"error updating %@ via sync:%@", rcfname, err);
					[self.syncDelegate dbsync:self syncComplete:NO error:err];
					return;
				}
			} else {
				//synchronous call
				[[Rc2Server sharedInstance] importFile:furl fileName:rcfname toContainer:self.wspace error:&err];
				if (err) {
					Rc2LogError(@"error syncing %@ to rc2:%@", rcfname, err);
					[self.syncDelegate dbsync:self syncComplete:NO error:err];
					return;
				} else {
					NSLog(@"uploaded %@ to rc2", rcfname);
				}
			}
		}
		//TODO: add files to db
		for (NSString *dbfname in addToDB) {
			Rc2LogInfo(@"adding %@ to db", dbfname);
		}
		Rc2LogInfo(@"regular sync complete");
		[self syncSuccessful];
	});
}

-(void)lookForConflicts
{
	NSSet *wsfilenames = [NSSet setWithArray:[[self.wspace.files arrayByPerformingSelector:@selector(name)] arrayByPerformingSelector:@selector(lowercaseString)]];
	NSMutableArray *conflicts = [NSMutableArray array];
	for (NSString *fname in _dloadedFiles) {
		if ([wsfilenames containsObject:fname.lowercaseString]) {
			[conflicts addObject:fname];
		}
	}
	if (conflicts.count > 0) {
		[self.syncDelegate dbsync:self syncComplete:NO error:[NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"conflict resolution not supported"}]];
		return;
	}
	[self uploadToDropbox];
}

-(void)startUploadToRc2
{
	NSMutableArray *files = [NSMutableArray array];
	[self.dloadedFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[files addObject:[NSURL fileURLWithPath:[self.tmpPath stringByAppendingPathComponent:obj]]];
	}];
	[[Rc2Server sharedInstance] importFiles:files toContainer:self.wspace completionHandler:^(BOOL success, id results) {
		if (!success) {
			NSLog(@"error importing to rc2:%@", results);
			[self.syncDelegate dbsync:self syncComplete:NO error:[NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:results}]];
		} else {
			NSLog(@"sync complete");
			self.state = kLastMetaRefresh;
			[self.client loadMetadata:self.wspace.dropboxPath];
			[self syncSuccessful];
		}
	} progress:^(CGFloat per) {
		[self.syncDelegate dbsync:self updateProgress:per message:nil];
	}];
}

-(void)uploadToDropbox
{
	self.state = kUploadingToDropbox;
	for (RCFile *file in self.wspace.files) {
		Rc2LogInfo(@"uploading %@ to dropbox", file.name);
		++_filesUploadingToDB;
		if ([_fm fileExistsAtPath:file.fileContentsPath])
			[self.client uploadFile:file.name toPath:self.wspace.dropboxPath withParentRev:nil fromPath:file.fileContentsPath];
		else {
			[file updateContentsFromServer:^(NSInteger success) {
				if (success)
					[self.client uploadFile:file.name toPath:self.wspace.dropboxPath withParentRev:nil fromPath:file.fileContentsPath];
			}];
		}
	}
}

-(void)syncSuccessful
{
	self.wspace.dropboxHash = self.metad.hash;
	self.wspace.dropboxHistory = [self serializeFilesToJSON];
	[[Rc2Server sharedInstance] updateWorkspace:self.wspace completionBlock:^(BOOL success, id results) {
		[self.syncDelegate dbsync:self syncComplete:YES error:nil];
	}];	
}

-(void)processNextDropboxFile
{
	//need to bounds check
	if (_curFileIdx >= self.metad.contents.count) {
		//done processing files
		Rc2LogInfo(@"done with files");
		[self lookForConflicts];
		return;
	}
	DBMetadata *meta = [self.metad.contents objectAtIndex:self.curFileIdx];
	if (meta.isDirectory) {
		//skip to next file
		_curFileIdx++;
		[self processNextDropboxFile];
		return;
	}
	//it is a file. download it if not too large
	if ((meta.totalBytes > 1024 * 1024 *10) || ![_vaildExtensions containsObject:meta.filename.lowercaseString.pathExtension]) {
		//file too large or invalid extension
		Rc2LogInfo(@"skipping %@ for size/extension", meta.filename);
		_curFileIdx++;
		[self processNextDropboxFile];
		return;
	}
	//load next file
	[self.client loadFile:meta.path intoPath:[_tmpPath stringByAppendingPathComponent:meta.filename]];
}

-(void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
	NSLog(@"%@ lastmod=%@", [destPath lastPathComponent], metadata.lastModifiedDate);
	[self.dloadedFiles addObject:[destPath lastPathComponent]];
	++_curFileIdx;
	[self processNextDropboxFile];
}

-(void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
	Rc2LogError(@"error dloading file:%@", error);
	[self.syncDelegate dbsync:self syncComplete:NO error:error];
}

-(void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
		  metadata:(DBMetadata*)metadata
{
	--_filesUploadingToDB;
	if (_filesUploadingToDB < 1) {
		NSLog(@"uploads complete");
		self.state = kUploadingToRc2;
		[self startUploadToRc2];
	}
}

-(void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error;
{
	[self.client cancelAllRequests];
	[self.syncDelegate dbsync:self syncComplete:NO error:error];
}

-(void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
	self.metad = metadata;
	[self loadedMetadata];
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
	NSLog(@"md unchanged");
}

-(void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
	Rc2LogError(@"dropbox error syncing workspace:%@", error);
	[self.syncDelegate dbsync:self syncComplete:NO error:error];
}

-(void)lsTmp
{
	for (NSString *aFile in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_tmpPath error:nil])
		NSLog(@"%@", aFile);
}

@end
