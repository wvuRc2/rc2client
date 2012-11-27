//
//  Rc2Server.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "Rc2Server.h"
#import "ASIFormDataRequest.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCWorkspaceShare.h"
#import "RCFile.h"
#import "RCCourse.h"
#import "RCAssignment.h"
#import "RC2RemoteLogger.h"
#import "SBJsonParser.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "NSObject+SBJSON.h"
#import "NSString+SBJSON.h"
#endif
#import "RCMessage.h"
#import "RCProject.h"
#import "Rc2FileType.h"

#define kServerHostKey @"ServerHostKey"

NSString * const WorkspaceItemsChangedNotification = @"WorkspaceItemsChangedNotification";
NSString * const NotificationsReceivedNotification = @"NotificationsReceivedNotification";
NSString * const MessagesUpdatedNotification = @"MessagesUpdatedNotification";

#pragma mark -

@interface Rc2Server()
@property (nonatomic, assign, readwrite) BOOL loggedIn;
@property (nonatomic, copy, readwrite) NSString *currentLogin;
@property (nonatomic, readwrite) BOOL isAdmin;
@property (nonatomic, strong, readwrite) NSNumber *currentUserId;
@property (nonatomic, copy, readwrite) NSArray *projects;
@property (nonatomic, strong) NSMutableDictionary *cachedData;
@property (nonatomic, strong) NSMutableDictionary *cachedDataTimestamps;
@property (nonatomic, strong) NSMutableDictionary *wsItemsById;
@property (nonatomic, strong) RC2RemoteLogger *remoteLogger;
@property (nonatomic, strong) NSOperationQueue *requestQueue;
@property (nonatomic, strong) SBJsonParser *jsonParser;
@end

#pragma mark -

@implementation Rc2Server

#pragma mark - init

+(Rc2Server*)sharedInstance
{
	static dispatch_once_t pred;
	static Rc2Server *global;
	
	dispatch_once(&pred, ^{ 
		global = [[Rc2Server alloc] init];
	});
	
	return global;
}

+(NSArray*)acceptableTextFileSuffixes
{
	return [[Rc2FileType textFileTypes] valueForKey:@"extension"];
}

+(NSArray*)acceptableImportFileSuffixes
{
	return [[Rc2FileType importableFileTypes] valueForKey:@"extension"];
}

+(NSArray*)acceptableImageFileSuffixes
{
	return [[Rc2FileType imageFileTypes] valueForKey:@"extension"];
}

-(id)init
{
	self = [super init];
	self.serverHost = [[NSUserDefaults standardUserDefaults] integerForKey:kServerHostKey];
	self.wsItemsById = [NSMutableDictionary dictionary];
	self.jsonParser = [[SBJsonParser alloc] init];
#if TARGET_IPHONE_SIMULATOR
	self.serverHost = eRc2Host_Local;
#endif
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
	self.remoteLogger = [[RC2RemoteLogger alloc] init];
	self.remoteLogger.apiKey = @"sf92j5t9fk2kfkegfd110lsm";
#endif
	[[VyanaLogger sharedInstance] startLogging];
	[DDLog addLogger:self.remoteLogger];
	self.requestQueue = [[NSOperationQueue alloc] init];
	self.requestQueue.maxConcurrentOperationCount = 4;
	self.cachedDataTimestamps = [[NSMutableDictionary alloc] init];
	self.cachedData = [[NSMutableDictionary alloc] init];
	return self;
}

#pragma mark - basic functionality

-(NSString*)userAgentString
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1070)
	return @"Rc2 MacClient";
#else
	return @"Rc2 iPadClient";
#endif
}


-(NSString*)connectionDescription
{
	if (eRc2Host_Rc2 == self.serverHost)
		return self.currentLogin;
	if (eRc2Host_Barney == self.serverHost)
		return [NSString stringWithFormat:@"%@@barney", self.currentLogin];
	return [NSString stringWithFormat:@"%@@local", self.currentLogin];
}

-(void)setServerHost:(NSInteger)sh
{
	if (self.serverHost >= eRc2Host_Rc2 && self.serverHost <= eRc2Host_Local) {
		_serverHost = sh;
		[[NSUserDefaults standardUserDefaults] setInteger:sh forKey:kServerHostKey];
	}
}

-(NSString*)baseUrl
{
	switch (self.serverHost) {
		case eRc2Host_Local:
#if TARGET_IPHONE_SIMULATOR
			return @"http://localhost:8080/";
#endif
			return @"https://localhost:8443/";
		case eRc2Host_Barney:
			return @"https://barney.stat.wvu.edu:8443/";
		case eRc2Host_Rc2:
		default:
			return @"https://rc2.stat.wvu.edu:8443/";
	}
}

-(NSString*)websocketUrl
{
	switch (self.serverHost) {
		case eRc2Host_Local:
#if TARGET_IPHONE_SIMULATOR
			return @"ws://localhost:8080/iR/ws";
#endif
			return @"ws://localhost:8443/iR/ws";
		case eRc2Host_Barney:
			return @"ws://barney.stat.wvu.edu:8080/iR/ws";
		case eRc2Host_Rc2:
		default:
			return @"ws://rc2.stat.wvu.edu:8080/iR/ws";
	}
}


//this method should be called on any request being sent to the rc2 server
// it will set the user agent, appropriate security settings, and cookies
-(void)commonRequestSetup:(ASIHTTPRequest*)request
{
	request.userAgent = self.userAgentString;
	request.validatesSecureCertificate = NO;
	request.timeOutSeconds = 10;
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	__unsafe_unretained ASIHTTPRequest *blockReq = request;
	[request setFailedBlock:^{
		[NSApp presentError:blockReq.error];
	}];
#endif
}

//a convience method that calls commonRequestSetup
-(ASIHTTPRequest*)requestWithURL:(NSURL*)url
{
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	[self commonRequestSetup:req];
	return req;
}

-(ASIFormDataRequest*)postRequestWithURL:(NSURL*)url
{
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:url];
	req.requestMethod = @"POST";
	[self commonRequestSetup:req];
	return req;
}

-(ASIHTTPRequest*)requestWithRelativeURL:(NSString*)urlString
{
	if ([urlString hasPrefix:@"/"])
		urlString = [urlString substringFromIndex:1];
	NSURL *url = [NSURL URLWithString:[self.baseUrl stringByAppendingString:urlString]];
	return [self requestWithURL:url];
}

-(ASIFormDataRequest*)postRequestWithRelativeURL:(NSString*)urlString
{
	if ([urlString hasPrefix:@"/"])
		urlString = [urlString substringFromIndex:1];
	NSURL *url = [NSURL URLWithString:[self.baseUrl stringByAppendingString:urlString]];
	return [self postRequestWithURL:url];
}

-(BOOL)responseIsValidJSON:(ASIHTTPRequest*)request
{
	return [[request.responseHeaders objectForKey:@"Content-Type"] hasPrefix:@"application/json"];
}

-(void)broadcastWorkspaceItemsUpdated
{
	[[NSNotificationCenter defaultCenter] postNotificationName:WorkspaceItemsChangedNotification object:self];
}

#pragma mark - projects

-(void)createProject:(NSString*)projectName completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@proj", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	NSDictionary *d = @{@"name":projectName};
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [self.jsonParser objectWithString:respStr];
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			self.projects = [RCProject projectsForJsonArray:[rsp objectForKey:@"projects"] includeAdmin:self.isAdmin];
			hblock(YES, [self.projects firstObjectWithValue:projectName forKey:@"name"]);
		} else {
			hblock(NO, respStr);
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)editProject:(RCProject*)project newName:(NSString*)newName completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@proj/%@", [self baseUrl], project.projectId]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	req.requestMethod = @"PUT";
	NSDictionary *d = @{@"name":newName, @"id":project.projectId};
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [self.jsonParser objectWithString:respStr];
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			project.name = newName;
			self.projects = [self.projects sortedArrayUsingDescriptors:[RCProject projectSortDescriptors]];
			hblock(YES, project);
		} else {
			hblock(NO, respStr);
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

//will remove it from projects array before hblock called
-(void)deleteProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@proj/%@", [self baseUrl], project.projectId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	req.requestMethod = @"DELETE";
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [self.jsonParser objectWithString:respStr];
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			self.projects = [self.projects arrayByRemovingObjectAtIndex:[self.projects indexOfObject:project]];
			hblock(YES, nil);
		} else {
			hblock(NO, respStr);
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

#pragma mark - workspaces

//updates the project object, calls hblock with the new workspace
-(void)createWorkspace:(NSString*)wspaceName inProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@proj/%@/wspace", [self baseUrl], project.projectId]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	NSDictionary *d = @{@"name":wspaceName};
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [self.jsonParser objectWithString:respStr];
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			[project updateWithDictionary:[rsp objectForKey:@"project"]];
			//we need to add the updated project to our cache of workspaces
			hblock(YES, [project.workspaces firstObjectWithValue:[rsp objectForKey:@"wspaceId"] forKey:@"wspaceId"]);
		} else {
			hblock(NO, respStr);
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}


-(void)renameWorkspce:(RCWorkspaceItem*)wspace name:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__block __weak ASIFormDataRequest *req = theReq;
	req.requestMethod = @"PUT";
	[req setPostValue:newName forKey:@"name"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		BOOL success = [[rsp objectForKey:@"status"] intValue] == 0;
		if (success) {
			[wspace setName:newName];
			if (self.selectedWorkspace == wspace) {
				[self willChangeValueForKey:@"selectedWorkspace"];
				[self didChangeValueForKey:@"selectedWorkspace"];
			}
		}
		hblock(success, rsp);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)deleteWorkspce:(RCWorkspaceItem*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
/*	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__block __weak ASIHTTPRequest *req = theReq;
	req.requestMethod = @"DELETE";
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		BOOL success = [[rsp objectForKey:@"status"] intValue] == 0;
		if (success) {
			[self.wsItemsById removeObjectForKey:wspace.wspaceId];
			if (nil == wspace.parentId)
				[self.workspaceItems arrayByRemovingObjectAtIndex:[self.workspaceItems indexOfObject:wspace]];
			else
				[(RCWorkspaceFolder*)wspace.parentItem removeChild:wspace];
			[self broadcastWorkspaceItemsUpdated];
		}
		hblock(success, rsp);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
 */
}

//++COPIED++ (not needed)
-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@?use", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__block __weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		hblock(![[rsp objectForKey:@"status"] boolValue], rsp);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(id)savedSessionForWorkspace:(RCWorkspace*)workspace
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSArray *allSaved = [moc fetchObjectsArrayForEntityName:@"RCSavedSession" 
											  withPredicate:@"wspaceId = %@ and login like %@",
												 workspace.wspaceId, self.currentLogin];
	return [allSaved firstObject];
}

/*
-(void)updateWorkspaceItems:(NSArray*)items
{
	NSMutableDictionary *allWspaces = [NSMutableDictionary dictionary];
	NSMutableArray *rootObjects = [NSMutableArray array];
	for (NSDictionary *wsdict in items) {
		RCWorkspaceItem *anItem = [RCWorkspaceItem workspaceItemWithDictionary:wsdict];
		[allWspaces setObject:anItem forKey:anItem.wspaceId];
		if (nil == anItem.parentId)
			[rootObjects addObject:anItem];
		[self.wsItemsById setObject:anItem forKey:anItem.wspaceId];
	}
	//now add all objects to their parents
	for (RCWorkspaceItem *anItem in [allWspaces allValues]) {
		if (anItem.parentId) {
			RCWorkspaceFolder *folder = [allWspaces objectForKey:anItem.parentId];
			if (![folder isKindOfClass:[RCWorkspaceFolder class]]) {
				Rc2LogWarn(@"bad parent %@ for %@", anItem.parentId, anItem.wspaceId);
			}
			[folder addChild:anItem];
			anItem.parentItem = folder;
		}
	}
	[rootObjects sortUsingSelector:@selector(compareWithItem:)];
	self.workspaceItems = rootObjects;
	[self broadcastWorkspaceItemsUpdated];
}

-(void)enumerateWorkspaceItemArray:(NSArray*)items stop:(BOOL*)stop block:(void (^)(RCWorkspace *wspace, BOOL *stop))block
{
	for (id item in items) {
		if ([item isFolder])
			[self enumerateWorkspaceItemArray:[(RCWorkspaceFolder*)item children] stop:stop block:block];
		else
			block(item, stop);
		if (stop)
			return;
	}
}

-(void)enumerateWorkspacesWithBlock:(void (^)(RCWorkspace *wspace, BOOL *stop))block
{
	BOOL stop=NO;
	[self enumerateWorkspaceItemArray:self.workspaceItems stop:&stop block:block];
}

-(RCWorkspace*)workspaceWithId:(NSNumber*)wspaceId
{
	return [self.wsItemsById objectForKey:wspaceId];
}
 
 */

#pragma mark - workspaces (legacy iPad functionality)

-(void)prepareWorkspace:(Rc2FetchCompletionHandler)hblock
{
	[self prepareWorkspace:self.selectedWorkspace completionHandler:hblock];
}

-(void)selectWorkspaceWithId:(NSNumber*)wspaceId
{
/*	for (RCWorkspaceItem *item in self.workspaceItems) {
		if ([item.wspaceId isEqualToNumber:wspaceId] && !item.isFolder) {
			self.selectedWorkspace = (RCWorkspace*)item;
			return;
		} else if (item.isFolder) {
			RCWorkspaceItem *ws = [(RCWorkspaceFolder*)item childWithId:wspaceId];
			if (ws && !ws.isFolder) {
				self.selectedWorkspace = (RCWorkspace*)ws;
				return;
			}
		}
	}*/
}

#pragma mark - files

-(NSArray*)processFileListResponse:(NSArray*)inEntries
{
	NSMutableArray *entries = [NSMutableArray arrayWithArray:inEntries];
	//now we need to add any local files that haven't been sent to the server
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSSet *newFiles = [moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId == 0 and wspaceId == %@",
					   self.selectedWorkspace.wspaceId];
	[entries addObjectsFromArray:[newFiles allObjects]];
	[entries sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	return entries;
}

-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@/files", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		NSMutableArray *entries = [NSMutableArray arrayWithArray:[rsp objectForKey:@"files"]];
		//now we need to add any local files that haven't been sent to the server
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		NSSet *newFiles = [moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId == 0 and wspaceId == %@",
						   self.selectedWorkspace.wspaceId];
		[entries addObjectsFromArray:[newFiles allObjects]];
		[entries sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
		hblock(![[rsp objectForKey:@"status"] boolValue], entries);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)fetchBinaryFileContents:(RCFile*)file toPath:(NSString*)destPath progress:(id)progressView
			 completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl],
									   file.fileId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	req.downloadDestinationPath = destPath;
	req.downloadProgressDelegate = progressView;
	[req setCompletionBlock:^{
		hblock(YES, @"");
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[self.requestQueue addOperation:req];
}

-(void)fetchBinaryFileContentsSynchronously:(RCFile*)file
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl],
									   file.fileId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	req.downloadDestinationPath = file.fileContentsPath;
	[req startSynchronous];
}

-(NSString*)fetchFileContentsSynchronously:(RCFile*)file
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl],
									   file.fileId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	[theReq startSynchronous];
	if (theReq.error) {
		Rc2LogWarn(@"error fetching file synchronously:%@", theReq.error);
		return nil;
	}
	return theReq.responseString;
}

-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock
{
	ZAssert(file.isTextFile, @"can only fetch contents of a text file");
	if (!file.isTextFile) {
		dispatch_async(dispatch_get_main_queue(), ^{
			hblock(NO, @"file is not a text file");
		});
		return;
	}
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl],
									   file.fileId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		hblock(YES, respStr);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[self.requestQueue addOperation:req];
}

-(void)deleteFile:(RCFile*)file workspace:(RCWorkspace*)workspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@/files/%@", [self baseUrl],
									   workspace.wspaceId, file.fileId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	req.requestMethod = @"DELETE";
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *rsp = [respStr JSONValue];
		if (0 == [[rsp objectForKey:@"status"] integerValue]) {
			//we need to update anything holding that file in memory
			[workspace refreshFiles];
		}
		hblock(![[rsp objectForKey:@"status"] boolValue], rsp);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}
-(void)saveFile:(RCFile*)file workspace:(RCWorkspace*)workspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url=nil;
	if (file.existsOnServer)  {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl], file.fileId]];
		ASIFormDataRequest *theReq = [self postRequestWithURL:url];
		__weak ASIFormDataRequest *req = theReq;
		if (file.existsOnServer)
			[req setRequestMethod:@"PUT"];
		[req addRequestHeader:@"Content-Type" value:@"application/json"];
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		[d setObject:file.currentContents forKey:@"contents"];
		[d setObject:file.name forKey:@"name"];
		[d setObject:file.name.pathExtension forKey:@"type"];
		[d setObject:workspace.wspaceId forKey:@"wspaceid"];
		[req appendPostData:[[d JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
		[req setCompletionBlock:^{
			NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
			NSDictionary *dict = [self.jsonParser objectWithString:respStr];
			NSInteger status = [[dict objectForKey:@"status"] integerValue];
			if (dict) {
				if (status == 0) {
					NSString *oldContents = file.localEdits;
					[file updateWithDictionary:[dict objectForKey:@"file"]];
					file.fileContents = oldContents;
					[file discardEdits];
					hblock(YES, file);
				} else {
					hblock(NO, [dict objectForKey:@"message"]);
				}
			} else {
				hblock(NO, respStr);
			}
		}];
		[req setFailedBlock:^{
			hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
		}];
		[req startAsynchronous];
	} else {
		ASIFormDataRequest *theReq = [self postRequestWithRelativeURL:[NSString stringWithFormat:@"workspace/%@/files", workspace.wspaceId]];
		__weak ASIFormDataRequest *req = theReq;
		[req setPostFormat:ASIMultipartFormDataPostFormat];
		[req setPostValue:file.name forKey:@"name"];
		[req setPostValue:self.currentUserId forKey:@"userid"];
		[req setPostValue:workspace.wspaceId forKey:@"wspaceid"];
		[req setFile:file.fileContentsPath forKey:@"content"];
		[req setCompletionBlock:^{
			NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
			NSDictionary *dict = [respStr JSONValue];
			if ([[dict objectForKey:@"status"] intValue] == 0) {
				NSDictionary *fdata = [dict objectForKey:@"file"];
				RCFile *rcfile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
				[rcfile updateWithDictionary:fdata];
				hblock(YES, rcfile);
			} else {
				if ([dict objectForKey:@"error"])
					hblock(NO, [dict objectForKey:@"error"]);
				else
					hblock(NO, @"unknown error");
			}
		}];
		[req setFailedBlock:^{
			hblock(NO, @"unknown error");
		}];
		[req startAsynchronous];
	}
}

-(void)importFile:(NSURL*)fileUrl workspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	ASIFormDataRequest *theReq = [self postRequestWithRelativeURL:[NSString stringWithFormat:@"workspace/%@/files", wspace.wspaceId]];
	__weak ASIFormDataRequest *req = theReq;
	[req setPostValue:[fileUrl lastPathComponent] forKey:@"name"];
	[req setPostValue:self.currentUserId forKey:@"userid"];
	[req setPostValue:wspace.wspaceId forKey:@"wspaceid"];
	[req setFile:fileUrl.path forKey:@"content"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *dict = [respStr JSONValue];
		if ([[dict objectForKey:@"status"] intValue] == 0) {
			NSDictionary *fdata = [dict objectForKey:@"file"];
			RCFile *rcfile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
			[rcfile updateWithDictionary:fdata];
			hblock(YES, rcfile);
		} else {
			if ([dict objectForKey:@"error"])
				hblock(NO, [dict objectForKey:@"error"]);
			else
				hblock(NO, @"unknown error");
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, @"unknown error");
	}];
	[req startAsynchronous];
}

//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl name:(NSString*)filename workspace:(RCWorkspace*)workspace error:(NSError *__autoreleasing *)outError
{
	ASIFormDataRequest *req = [self postRequestWithRelativeURL:[NSString stringWithFormat:@"workspace/%@/files", workspace.wspaceId]];
	[req setPostValue:filename forKey:@"name"];
	[req setPostValue:self.currentUserId forKey:@"userid"];
	[req setPostValue:workspace.wspaceId forKey:@"wspaceid"];
	[req setFile:fileUrl.path forKey:@"content"];
	[req startSynchronous];
	if (req.error) {
		if (outError)
			*outError = req.error;
		return nil;
	}
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
	NSDictionary *dict = [respStr JSONValue];
	NSDictionary *fdata = [dict objectForKey:@"file"];
	RCFile *rcfile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
	[rcfile updateWithDictionary:fdata];
	[workspace addFile:rcfile];
	return rcfile;
}

//synchronously update the content of a file
-(BOOL)updateFile:(RCFile*)file withContents:(NSURL*)contentsFileUrl workspace:(RCWorkspace*)workspace  
			error:(NSError *__autoreleasing *)outError
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@file/%@", [self baseUrl], file.fileId]];
	ASIFormDataRequest *req = [self postRequestWithURL:url];
	[req setFile:contentsFileUrl.path forKey:@"content"];
	[req startSynchronous];
	if (req.error) {
		if (outError)
			*outError = req.error;
		return NO;
	}
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
	NSDictionary *dict = [self.jsonParser objectWithString:respStr error:outError];
	if (nil == dict)
		return NO;
	[file discardEdits];
	[file updateWithDictionary:[dict objectForKey:@"file"]];
	if (file.isTextFile)
		file.fileContents = [NSString stringWithContentsOfURL:contentsFileUrl encoding:NSUTF8StringEncoding error:nil];
	return YES;
}

#pragma mark - sharing

-(void)updateWorkspace:(RCWorkspace*)wspace withShareArray:(NSArray*)rawShares
{
	//TODO: should this be merged instead of nuking all existing objects?
	[wspace.shares removeAllObjects];
	for (NSDictionary *dict in rawShares) {
		RCWorkspaceShare *share = [[RCWorkspaceShare alloc] initWithDictionary:dict workspace:wspace];
		[wspace.shares addObject:share];
	}
}

//++COPIED++
-(void)fetchWorkspaceShares:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@/share", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		[wspace.shares removeAllObjects];
		for (NSDictionary *dict in [rsp objectForKey:@"shares"]) {
			RCWorkspaceShare *share = [[RCWorkspaceShare alloc] initWithDictionary:dict workspace:wspace];
			[wspace.shares addObject:share];
		}
		hblock(![[rsp objectForKey:@"status"] boolValue], wspace.shares);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(ASIHTTPRequest*)createUserSearchRequest:(NSString*)sstring searchType:(NSString*)searchType
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user", [self baseUrl]]];
	__block ASIFormDataRequest *req = [self postRequestWithURL:url];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:sstring, @"value", searchType, @"type", nil];
	[req appendPostData:[[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	return req;
}

#pragma mark - courses/assignments

-(BOOL)synchronouslyUpdateAssignment:(RCAssignment*)assignment withValues:(NSDictionary*)newVals
{
	ASIHTTPRequest *theReq = [self requestWithRelativeURL:[NSString stringWithFormat:@"courses/%@/assignment/%@", 
							   assignment.course.classId, assignment.assignmentId]];
	[theReq addRequestHeader:@"Content-Type" value:@"application/json"];
	[theReq setRequestMethod:@"PUT"];
	[theReq appendPostData:[[newVals JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[theReq startSynchronous];
	if (200 != theReq.responseStatusCode)
		return NO;
	if ([[[[theReq responseString] JSONValue] objectForKey:@"status"] intValue] == 0)
		return YES;
	return NO;
}

#pragma mark - messages

-(void)markMessageRead:(RCMessage*)message
{
	ASIHTTPRequest *req = [self requestWithRelativeURL:[NSString stringWithFormat:@"message/%@", message.rcptmsgId]];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[@"{}" dataUsingEncoding:NSUTF8StringEncoding]];
	req.requestMethod = @"PUT";
	
	[req startAsynchronous];
	message.dateRead = [NSDate date];
}

-(void)markMessageDeleted:(RCMessage*)message
{
	ASIHTTPRequest *req = [self requestWithRelativeURL:[NSString stringWithFormat:@"message/%@", message.rcptmsgId]];
	req.requestMethod = @"DELETE";
	[req startAsynchronous];
}

-(void)syncMessages:(Rc2FetchCompletionHandler)hblock
{
	ASIHTTPRequest *theReq = [self requestWithRelativeURL:@"messages"];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		if (req.responseStatusCode != 200) {
			hblock(NO, @"invalid server response");
			return;
		}
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		if ([rsp objectForKey:@"status"] && [[rsp objectForKey:@"status"] intValue] == 0) {
			[RCMessage syncFromJsonArray:[rsp objectForKey:@"messages"]];
			hblock(YES, nil);
			[[NSNotificationCenter defaultCenter] postNotificationName:MessagesUpdatedNotification object:self];
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

#pragma mark - login/logout

-(void)handleLoginResponse:(ASIHTTPRequest*)req forUser:(NSString*)user completionHandler:(Rc2FetchCompletionHandler)handler
{
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
//	[respStr writeToFile:@"/tmp/rc2.lastlogin.json" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	if (![self responseIsValidJSON:req]) {
		handler(NO, @"server sent back invalid response");
		return;
	}
	NSDictionary *rsp = [respStr JSONValue];
	if ([[rsp objectForKey:@"status"] intValue] != 0) {
		//error
		handler(NO, [rsp objectForKey:@"message"]);
	} else {
		//success
		self.currentLogin=user;
		self.currentUserId = [rsp objectForKey:@"userid"];
		self.isAdmin = [[rsp objectForKey:@"isAdmin"] boolValue];
		self.userSettings = [rsp objectForKey:@"settings"];
		[self.cachedData setObject:[rsp objectForKey:@"permissions"] forKey:@"permissions"];
		[self.cachedData setObject:[RCCourse classesFromJSONArray:[rsp objectForKey:@"classes"]] forKey:@"classesTaught"];
		[self.cachedData setObjectIgnoringNil:[rsp objectForKey:@"tograde"] forKey:@"tograde"];
		self.remoteLogger.logHost = [NSURL URLWithString:[NSString stringWithFormat:@"%@iR/al",
														  [self baseUrl]]];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
		UIDevice *dev = [UIDevice currentDevice];
		self.remoteLogger.clientIdent = [NSString stringWithFormat:@"%@/%@/%@/%@",
										 user, [dev systemName], [dev systemVersion], [dev model]];
#endif
		self.projects = [RCProject projectsForJsonArray:[rsp objectForKey:@"projects"] includeAdmin:self.isAdmin];
		self.loggedIn=YES;
		handler(YES, rsp);
		[[NSNotificationCenter defaultCenter] postNotificationName:NotificationsReceivedNotification 
															object:self 
														  userInfo:[NSDictionary dictionaryWithObject:[rsp objectForKey:@"notes"] forKey:@"notes"]];
	}
}

-(void)loginAsUser:(NSString*)user password:(NSString*)password completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@login", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	[req setTimeOutSeconds:5];
	[req setPostValue:user forKey:@"login"];
	[req setPostValue:password forKey:@"password"];
	[req setCompletionBlock:^{
		[[Rc2Server sharedInstance] handleLoginResponse:req forUser:user completionHandler:hblock];
	}];
	[req setFailedBlock:^{
		Rc2LogError(@"login request failed:%@", req.error);
		NSString *msg = [NSString stringWithFormat:@"server returned %d", req.responseStatusCode];
		if (req.responseStatusCode == 0)
			msg = @"Server not responding";
		hblock(NO, msg);
	}];
	[req startAsynchronous];
}

-(void)logout
{
	self.selectedWorkspace=nil;
	self.loggedIn=NO;
	self.currentLogin=nil;
	self.remoteLogger.logHost=nil;
	[self.cachedData removeAllObjects];
	[self.cachedDataTimestamps removeAllObjects];
	//FIXME: need to send a logout request to server
}

#pragma mark - accessors

-(NSArray*)usersPermissions
{
	return [self.cachedData objectForKey:@"permissions"];
}

-(NSArray*)classesTaught
{
	return [self.cachedData objectForKey:@"classesTaught"];
}

-(NSArray*)assignmentsToGrade
{
	return [self.cachedData objectForKey:@"tograde"];
}

-(NSArray*)messageRecipients
{
	NSArray *rcpts = [self.cachedData objectForKey:@"messageRecipients"];
	NSDate *date = [self.cachedDataTimestamps objectForKey:@"messageRecipients"];
	if (rcpts && ([NSDate timeIntervalSinceReferenceDate] - date.timeIntervalSinceReferenceDate > 300)) {
		//if data is less than 5 minutes old, use it
		return rcpts;
	}
	ASIHTTPRequest *req = [self requestWithRelativeURL:@"messages?pm"];
	__unsafe_unretained ASIHTTPRequest *blockReq = req;
	if (rcpts) {
		//old data, return it but trigger a refresh. KVO can be used to get the update
		[req setCompletionBlock:^{
			if (blockReq.responseStatusCode == 200)
				[[Rc2Server sharedInstance] handleMessageRcpts:[blockReq.responseString JSONValue]];
		}];
		[req startAsynchronous];
		return rcpts;
	}
	//we need to fetch them synchronously
	[req startSynchronous];
	if (req.responseStatusCode != 200) {
		Rc2LogError(@"error fetching message rcpt list: %d", req.responseStatusCode);
		return nil;
	}
	return [self handleMessageRcpts:[req.responseString JSONValue]];
}

-(NSArray*)handleMessageRcpts:(NSDictionary*)resp
{
	if (nil == [resp objectForKey:@"rcpts"]) {
		Rc2LogWarn(@"server returned no message rcpts");
		return nil;
	}
	NSArray *rcpts = [[resp objectForKey:@"rcpts"] sortedArrayUsingDescriptors:ARRAY([NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES])];
	[self willChangeValueForKey:@"messageRecipients"];
	[self.cachedDataTimestamps setObject:[NSDate date] forKey:@"messageRecipients"];
	[self.cachedData setObject:rcpts forKey:@"messageRecipients"];
	[self didChangeValueForKey:@"messageRecipients"];
	return rcpts;
}

@end
