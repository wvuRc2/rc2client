//
//  Rc2Server.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "Rc2Server.h"
#import "ASIFormDataRequest.h"
#import "NSObject+SBJSON.h"
#import "NSString+SBJSON.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCMessage.h"

#define kServerHostKey @"ServerHostKey"
#define kUserAgent @"Rc2 iPadClient"

@interface Rc2Server()
@property (nonatomic, assign, readwrite) BOOL loggedIn;
@property (nonatomic, copy, readwrite) NSString *currentLogin;
@property (nonatomic, copy, readwrite) NSArray *workspaceItems;
-(void)updateWorkspaceItems:(NSArray*)items;
@end

@implementation Rc2Server
@synthesize serverHost=_serverHost;
@synthesize loggedIn=_loggedIn;
@synthesize workspaceItems=_workspaceItems;
@synthesize selectedWorkspace=_selectedWorkspace;
@synthesize currentSession=_currentSession;
@synthesize currentLogin;

+(Rc2Server*)sharedInstance
{
	static dispatch_once_t pred;
	static Rc2Server *global;
	
	dispatch_once(&pred, ^{ 
		global = [[Rc2Server alloc] init];
	});
	
	return global;
}

#pragma mark - init

-(id)init
{
	self = [super init];
	self.serverHost = [[NSUserDefaults standardUserDefaults] integerForKey:kServerHostKey];
#if TARGET_IPHONE_SIMULATOR
	self.serverHost = eRc2Host_Local;
#endif
	return self;
}

-(void)logout
{
	self.selectedWorkspace=nil;
	self.workspaceItems=nil;
	self.loggedIn=NO;
	self.currentLogin=nil;
	//FIXME:: need to send a logout request to server
}

-(void)setServerHost:(NSInteger)sh
{
	if (self.serverHost >= eRc2Host_Harner && self.serverHost <= eRc2Host_Local) {
		_serverHost = sh;
		[[NSUserDefaults standardUserDefaults] setInteger:sh forKey:kServerHostKey];
	}
}

-(NSString*)baseUrl
{
	switch (self.serverHost) {
		case eRc2Host_Local:
			return @"http://localhost:8080/";
		case eRc2Host_Barney:
			return @"http://barney.stat.wvu.edu:8080/";
		case eRc2Host_Harner:
		default:
			return @"http://harner.stat.wvu.edu:8080/";
	}
}

-(void)addWorkspace:(NSString*)name parent:(RCWorkspaceFolder*)parent folder:(BOOL)isFolder
	completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspaces", [self baseUrl]]];
	__block ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:url];
	req.userAgent = kUserAgent;
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

-(RCSavedSession*)savedSessionForWorkspace:(RCWorkspace*)workspace
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSArray *allSaved = [moc fetchObjectsArrayForEntityName:@"RCSavedSession" 
											  withPredicate:@"wspaceId = %@ and login like %@",
												 workspace.wspaceId, self.currentLogin];
	return [allSaved firstObject];
}

-(void)selecteWorkspaceWithId:(NSNumber*)wspaceId
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
				NSLog(@"bad parent");
			}
			[folder addChild:anItem];
		}
	}
	[rootObjects sortUsingSelector:@selector(compareWithItem:)];
	self.workspaceItems = rootObjects;
}

-(NSArray*)processFileListResponse:(NSDictionary*)rsp
{
	NSMutableArray *entries = [NSMutableArray arrayWithArray:[rsp objectForKey:@"entries"]];
	//now we need to add any local files that haven't been sent to the server
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSSet *newFiles = [moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId == 0 and wspaceId == %@",
					   self.selectedWorkspace.wspaceId];
	[entries addObjectsFromArray:[newFiles allObjects]];
	return entries;
}

-(void)markMessageRead:(RCMessage*)message
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/message/%@/read", [self baseUrl], message.rcptmsgId]];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.requestMethod = @"PUT";
	req.userAgent = kUserAgent;
	[req startAsynchronous];
	message.dateRead = [NSDate date];
}

-(void)markMessageDeleted:(RCMessage*)message
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/message/%@", [self baseUrl], message.rcptmsgId]];
	ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.requestMethod = @"DELETE";
	req.userAgent = kUserAgent;
	[req startAsynchronous];
}

-(void)syncMessages:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/messages", [self baseUrl]]];
	__block ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.userAgent = kUserAgent;
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

-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/ftree/%@", [self baseUrl],
									   self.selectedWorkspace.wspaceId]];
	__block ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.userAgent = kUserAgent;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		NSArray *entries = [self processFileListResponse:rsp];
		hblock(![[rsp objectForKey:@"status"] boolValue], entries);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
									   file.fileId]];
	__block ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.userAgent = kUserAgent;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		hblock(YES, respStr);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)deleteFile:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl],
									   file.fileId]];
	__block ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.userAgent = kUserAgent;
	req.requestMethod = @"DELETE";
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *rsp = [respStr JSONValue];
		if ([[rsp objectForKey:@"status"] boolValue]) {
			//we need to update anything holding that file in memory
			[self.selectedWorkspace refreshFiles];
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
	NSURL *url=nil;
	if (file.existsOnServer)
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/%@", [self baseUrl], file.fileId]];
	else
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/files/new", [self baseUrl]]];
	__block ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:url];
	req.userAgent = kUserAgent;
	[req setPostValue:file.localEdits forKey:@"content"];
	[req setPostValue:file.name forKey:@"name"];
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		NSDictionary *dict = [respStr JSONValue];
		[file updateWithDictionary:[dict objectForKey:@"file"]];
		file.fileContents = file.localEdits;
		file.localEdits = @"";
		hblock(YES, file);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)prepareWorkspace:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/wspace/use/%@", [self baseUrl],
									   self.selectedWorkspace.wspaceId]];
	__block ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
	req.userAgent = kUserAgent;
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
		[self updateWorkspaceItems:[rsp objectForKey:@"wsitems"]];
		handler(YES, nil);
	}
}

-(void)loginAsUser:(NSString*)user password:(NSString*)password completionHandler:(Rc2SessionCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/login", [self baseUrl]]];
	__block ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:url];
	req.userAgent = kUserAgent;
	[req setPostValue:user forKey:@"login"];
	[req setPostValue:password forKey:@"password"];
	[req setCompletionBlock:^{
		[[Rc2Server sharedInstance] handleLoginResponse:req forUser:user completionHandler:hblock];
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

@end
