//
//  Rc2Server.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "Rc2Server.h"
#import "ASIFormDataRequest.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCWorkspaceShare.h"
#import "RCFile.h"
#import "RC2RemoteLogger.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "NSObject+SBJSON.h"
#import "NSString+SBJSON.h"
#else
#import "RCMessage.h"
#endif

#define kServerHostKey @"ServerHostKey"
#define kUserAgent @"Rc2 iPadClient"

#pragma mark -

@interface Rc2Server()
@property (nonatomic, assign, readwrite) BOOL loggedIn;
@property (nonatomic, copy, readwrite) NSString *currentLogin;
@property (nonatomic, readwrite) BOOL isAdmin;
@property (nonatomic, strong) NSNumber *currentUserId;
@property (nonatomic, copy, readwrite) NSArray *workspaceItems;
@property (nonatomic, strong) RC2RemoteLogger *remoteLogger;
@property (nonatomic, strong) NSOperationQueue *requestQueue;
-(void)updateWorkspaceItems:(NSArray*)items;
@end

#pragma mark -

@implementation Rc2Server

#pragma mark - synthesizers

@synthesize serverHost=_serverHost;
@synthesize loggedIn=_loggedIn;
@synthesize workspaceItems=_workspaceItems;
@synthesize selectedWorkspace=_selectedWorkspace;
@synthesize currentSession=_currentSession;
@synthesize currentLogin;
@synthesize remoteLogger;
@synthesize currentUserId;
@synthesize isAdmin;
@synthesize requestQueue;

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
	static NSArray *fileExts=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fileExts = [[NSMutableArray alloc] initWithObjects:@"txt", @"R", @"Rnw", @"csv", @"tsv", @"tab", nil];
	});
	return fileExts;
}

+(NSArray*)acceptableImportFileSuffixes
{
	static NSArray *fileExts=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fileExts = [[NSMutableArray alloc] initWithObjects:@"txt", @"R", @"Rnw", @"csv", @"tsv", @"tab", @"pdf", nil];
	});
	return fileExts;
}

-(id)init
{
	self = [super init];
	self.serverHost = [[NSUserDefaults standardUserDefaults] integerForKey:kServerHostKey];
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
	return self;
}

#pragma mark - basic functionality

-(NSString*)userAgentString
{
	return kUserAgent;
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
			return @"http://barney.stat.wvu.edu:8080/";
		case eRc2Host_Rc2:
		default:
			return @"http://rc2.stat.wvu.edu:8080/";
	}
}


//this method should be called on any request being sent to the rc2 server
// it will set the user agent, appropriate security settings, and cookies
-(void)commonRequestSetup:(ASIHTTPRequest*)request
{
	request.userAgent = self.userAgentString;
	request.validatesSecureCertificate = NO;
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	__block __weak NSError *error = request.error;
	[request setFailedBlock:^{
		[NSApp presentError:error];
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


#pragma mark - workspaces

-(void)addWorkspace:(NSString*)name parent:(RCWorkspaceFolder*)parent folder:(BOOL)isFolder
	completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspaces", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	[req setPostValue:name forKey:@"newname"];
	if (isFolder)
		[req setPostValue:@"f" forKey:@"newtype"];
	[req setPostValue:[NSString stringWithFormat:@"%d", parent.wspaceId.intValue] forKey:@"parent"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
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

-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspace/use/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__block __weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
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

-(void)updateWorkspaceItems:(NSArray*)items
{
	NSMutableDictionary *allWspaces = [NSMutableDictionary dictionary];
	NSMutableArray *rootObjects = [NSMutableArray array];
	for (NSDictionary *wsdict in items) {
		RCWorkspaceItem *anItem = [RCWorkspaceItem workspaceItemWithDictionary:wsdict];
		[allWspaces setObject:anItem forKey:anItem.wspaceId];
		if (nil == anItem.parentId)
			[rootObjects addObject:anItem];
	}
	//now add all objects to their parents
	for (RCWorkspaceItem *anItem in [allWspaces allValues]) {
		if (anItem.parentId) {
			RCWorkspaceFolder *folder = [allWspaces objectForKey:anItem.parentId];
			if (![folder isKindOfClass:[RCWorkspaceFolder class]]) {
				Rc2LogWarn(@"bad parent %@ for %@", anItem.parentId, anItem.wspaceId);
			}
			[folder addChild:anItem];
		}
	}
	[rootObjects sortUsingSelector:@selector(compareWithItem:)];
	self.workspaceItems = rootObjects;
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

#pragma mark - workspaces (legacy iPad functionality)

-(void)prepareWorkspace:(Rc2FetchCompletionHandler)hblock
{
	[self prepareWorkspace:self.selectedWorkspace completionHandler:hblock];
}

-(void)selectWorkspaceWithId:(NSNumber*)wspaceId
{
	for (RCWorkspaceItem *item in self.workspaceItems) {
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
	}
}

#pragma mark - files

-(RCWorkspace*)workspaceForFile:(RCFile*)file
{
	__block RCWorkspace *theWspace=nil;
	[self enumerateWorkspacesWithBlock:^(RCWorkspace *wspace, BOOL *stop) {
		if ([wspace fileWithId:file.fileId]) {
			theWspace = wspace;
			*stop = YES;
		}
	}];
	return theWspace;
}

-(NSArray*)processFileListResponse:(NSArray*)inEntries
{
	NSMutableArray *entries = [NSMutableArray arrayWithArray:inEntries];
	//now we need to add any local files that haven't been sent to the server
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSSet *newFiles = [moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId == 0 and wspaceId == %@",
					   self.selectedWorkspace.wspaceId];
	[entries addObjectsFromArray:[newFiles allObjects]];
	return entries;
}

-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/ftree/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		NSArray *entries = [self processFileListResponse:[rsp objectForKey:@"entries"]];
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
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

-(NSString*)fetchFileContentsSynchronously:(RCFile*)file
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
									   file.fileId]];
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

-(void)saveFile:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[self saveFile:file workspace:self.selectedWorkspace completionHandler:hblock];
}

-(void)saveFile:(RCFile*)file workspace:(RCWorkspace*)workspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url=nil;
	if (file.existsOnServer)
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl], file.fileId]];
	else
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/new", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	[req setPostValue:file.localEdits forKey:@"content"];
	[req setPostValue:file.name forKey:@"name"];
	[req setPostValue:workspace.wspaceId forKey:@"wspaceid"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *dict = [respStr JSONValue];
		NSString *oldContents = file.localEdits;
		[file updateWithDictionary:[dict objectForKey:@"file"]];
		file.fileContents = oldContents;
		[file discardEdits];
		hblock(YES, file);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)importFile:(NSURL*)fileUrl workspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/new", self.baseUrl]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	[req setPostValue:[fileUrl lastPathComponent] forKey:@"name"];
	[req setPostValue:self.currentUserId forKey:@"userid"];
	[req setPostValue:wspace.wspaceId forKey:@"wspaceid"];
	[req setFile:fileUrl.path forKey:@"content"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *dict = [respStr JSONValue];
		NSDictionary *fdata = [dict objectForKey:@"file"];
		RCFile *rcfile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
		[rcfile updateWithDictionary:fdata];
		hblock(YES, rcfile);
	}];
	[req setFailedBlock:^{
		hblock(NO, @"unknown error");
	}];
	[req startAsynchronous];
}

//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl name:(NSString*)filename workspace:(RCWorkspace*)workspace error:(NSError *__autoreleasing *)outError
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/new", self.baseUrl]];
	ASIFormDataRequest *req = [self postRequestWithURL:url];
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
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl], file.fileId]];
	ASIFormDataRequest *req = [self postRequestWithURL:url];
	[req setFile:contentsFileUrl.path forKey:@"content"];
	[req startSynchronous];
	if (req.error) {
		if (outError)
			*outError = req.error;
		return NO;
	}
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
	NSDictionary *dict = [respStr JSONValue];
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

-(void)fetchWorkspaceShares:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspace/share/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		[self updateWorkspace:wspace withShareArray:[rsp objectForKey:@"shares"]];
		hblock(![[rsp objectForKey:@"status"] boolValue], wspace.shares);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(ASIHTTPRequest*)createUserSearchRequest:(NSString*)sstring
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspace/share/search", [self baseUrl]]];
	__block ASIFormDataRequest *req = [self postRequestWithURL:url];
	[req setPostValue:sstring forKey:@"s"];
	return req;
}

#pragma mark - messages

#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
-(void)markMessageRead:(RCMessage*)message
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/message/%@/read", [self baseUrl], message.rcptmsgId]];
	ASIHTTPRequest *req = [self requestWithURL:url];
	req.requestMethod = @"PUT";
	[req startAsynchronous];
	message.dateRead = [NSDate date];
}

-(void)markMessageDeleted:(RCMessage*)message
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/message/%@", [self baseUrl], message.rcptmsgId]];
	ASIHTTPRequest *req = [self requestWithURL:url];
	req.requestMethod = @"DELETE";
	[req startAsynchronous];
}

-(void)syncMessages:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/messages", [self baseUrl]]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		[RCMessage syncFromJsonArray:[rsp objectForKey:@"messages"]];
		hblock(![[rsp objectForKey:@"status"] boolValue], nil);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}
#endif

#pragma mark - login/logout

-(void)handleLoginResponse:(ASIHTTPRequest*)req forUser:(NSString*)user completionHandler:(Rc2SessionCompletionHandler)handler
{
	NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
	if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
		handler(NO, @"server sent back invalid response");
		return;
	}
	NSDictionary *rsp = [respStr JSONValue];
	if ([[rsp objectForKey:@"status"] intValue] != 0) {
		//error
		handler(NO, [rsp objectForKey:@"error"]);
	} else {
		//success
		self.loggedIn=YES;
		self.currentLogin=user;
		self.currentUserId = [rsp objectForKey:@"userid"];
		self.isAdmin = [[rsp objectForKey:@"isadmin"] boolValue];
		self.remoteLogger.logHost = [NSURL URLWithString:[NSString stringWithFormat:@"%@iR/al",
														  [self baseUrl]]];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
		UIDevice *dev = [UIDevice currentDevice];
		self.remoteLogger.clientIdent = [NSString stringWithFormat:@"%@/%@/%@/%@",
										 user, [dev systemName], [dev systemVersion], [dev model]];
#endif
		[self updateWorkspaceItems:[rsp objectForKey:@"wsitems"]];
		handler(YES, nil);
		Rc2LogInfo(@"logged in");
	}
}

-(void)loginAsUser:(NSString*)user password:(NSString*)password completionHandler:(Rc2SessionCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/login", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	[req setTimeOutSeconds:10];
	[req setPostValue:user forKey:@"login"];
	[req setPostValue:password forKey:@"password"];
	[req setCompletionBlock:^{
		[[Rc2Server sharedInstance] handleLoginResponse:req forUser:user completionHandler:hblock];
	}];
	[req setFailedBlock:^{
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
	self.workspaceItems=nil;
	self.loggedIn=NO;
	self.currentLogin=nil;
	self.remoteLogger.logHost=nil;
	//FIXME: need to send a logout request to server
}

@end
