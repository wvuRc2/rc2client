//
//  Rc2Server.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCCourse.h"
#import "RCUser.h"
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
#import "AFJSONRequestOperation.h"

#define kServerHostKey @"ServerHostKey"

NSString * const WorkspaceItemsChangedNotification = @"WorkspaceItemsChangedNotification";
NSString * const NotificationsReceivedNotification = @"NotificationsReceivedNotification";
NSString * const MessagesUpdatedNotification = @"MessagesUpdatedNotification";

#pragma mark -

@interface Rc2Server()
@property (nonatomic, strong, readwrite) AFHTTPClient *httpClient;
@property (nonatomic, assign, readwrite) BOOL loggedIn;
@property (nonatomic, copy, readwrite) NSString *currentLogin;
@property (nonatomic, readwrite) BOOL isAdmin;
@property (nonatomic, strong, readwrite) NSNumber *currentUserId;
@property (nonatomic, copy, readwrite) NSArray *projects;
@property (nonatomic, strong) NSMutableDictionary *cachedData;
@property (nonatomic, strong) NSMutableDictionary *cachedDataTimestamps;
@property (nonatomic, strong) RC2RemoteLogger *remoteLogger;
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

-(void)broadcastWorkspaceItemsUpdated
{
	[[NSNotificationCenter defaultCenter] postNotificationName:WorkspaceItemsChangedNotification object:self];
}

-(NSMutableString*)containerPath:(id<RCFileContainer>)container
{
	NSMutableString *path = [NSMutableString stringWithFormat:@"proj/%@", [container projectId]];
	if ([container isKindOfClass:[RCWorkspace class]])
		[path appendFormat:@"/wspace/%@", [(RCWorkspace*)container wspaceId]];
	return path;
}

//generic internal method to reduce code
-(void)genericGetRequest:(NSString*)path parameters:(NSDictionary*)params handler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableURLRequest *req = [_httpClient requestWithMethod:@"GET" path:path parameters:nil];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id op, id rsp) {
		hblock(YES, rsp);
	} failure:^(id op, NSError *error) {
		hblock(NO, error.localizedDescription);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
}

#pragma mark - projects

-(void)createProject:(NSString*)projectName completionBlock:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient postPath:@"proj" parameters:@{@"name":projectName} success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			self.projects = [RCProject projectsForJsonArray:[rsp objectForKey:@"projects"] includeAdmin:self.isAdmin];
			hblock(YES, [self.projects firstObjectWithValue:projectName forKey:@"name"]);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)editProject:(RCProject*)project newName:(NSString*)newName completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSString *path = [NSString stringWithFormat:@"proj/%@", project.projectId];
	[_httpClient putPath:path parameters:@{@"name":newName, @"id":project.projectId} success:^(id op, id rsp) {
		if ([[rsp objectForKey:@"status"] intValue] == 0) {
			project.name = newName;
			self.projects = [self.projects sortedArrayUsingDescriptors:[RCProject projectSortDescriptors]];
			hblock(YES, project);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

//will remove it from projects array before hblock called
-(void)deleteProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSString *path = [NSString stringWithFormat:@"proj/%@", project.projectId];
	[_httpClient deletePath:path parameters:nil success:^(id op, id rsp) {
		if ([[rsp objectForKey:@"status"] intValue] == 0) {
			self.projects = [self.projects arrayByRemovingObjectAtIndex:[self.projects indexOfObject:project]];
			hblock(YES, nil);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

#pragma mark - workspaces

//updates the project object, calls hblock with the new workspace
-(void)createWorkspace:(NSString*)wspaceName inProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock
{
	NSString *path = [NSString stringWithFormat:@"proj/%@/wspace", project.projectId];
	[_httpClient postPath:path parameters:@{@"name":wspaceName} success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			[project updateWithDictionary:[rsp objectForKey:@"project"]];
			//we need to add the updated project to our cache of workspaces
			hblock(YES, [project.workspaces firstObjectWithValue:[rsp objectForKey:@"wspaceId"] forKey:@"wspaceId"]);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)renameWorkspce:(RCWorkspace*)wspace name:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;
{
	[_httpClient putPath:[self containerPath:wspace] parameters:@{@"name":newName} success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			wspace.name = newName;
			hblock(YES, wspace);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)deleteWorkspce:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient deletePath:[self containerPath:wspace] parameters:nil success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			[wspace.project removeWorkspace:wspace];
			hblock(YES, nil);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)refereshWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSString *path = [NSString stringWithFormat:@"proj/%@/wspace/%@", wspace.projectId, wspace.wspaceId];
	[self genericGetRequest:path parameters:nil handler:hblock];
}

-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[self genericGetRequest:[NSString stringWithFormat:@"workspace/%@?use", wspace.wspaceId] parameters:nil handler:^(BOOL success, id results) {
		hblock(success, results);
	}];
}

-(id)savedSessionForWorkspace:(RCWorkspace*)workspace
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	NSArray *allSaved = [moc fetchObjectsArrayForEntityName:@"RCSavedSession" 
											  withPredicate:@"wspaceId = %@ and login like %@",
												 workspace.wspaceId, self.currentLogin];
	return [allSaved firstObject];
}

-(RCWorkspace*)workspaceWithId:(NSNumber*)wspaceId
{
	for (RCProject *project in [Rc2Server sharedInstance].projects) {
		for (RCWorkspace *wspace in project.workspaces) {
			if ([wspace.wspaceId isEqualToNumber:wspaceId])
				return wspace;
		}
	}
	return nil;
}


#pragma mark - files

-(void)downloadAppPath:(NSString*)path toFilePath:(NSString*)filePath completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableURLRequest *req = [_httpClient requestWithMethod:@"GET" path:path parameters:nil];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id op, id rsp) {
		if (hblock)
			hblock(YES, nil);
	} failure:^(id op, NSError *error) {
		if (hblock)
			hblock(NO, error.localizedDescription);
	}];
	op.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
	[_httpClient enqueueHTTPRequestOperation:op];
}

-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
	NSMutableURLRequest *req = [_httpClient requestWithMethod:@"GET" path:path parameters:nil];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id op, id rsp) {
		hblock(YES, [NSString stringWithUTF8Data:rsp]);
	} failure:^(id op, NSError *error) {
		hblock(NO, error.localizedDescription);
	}];
	NSString *fpath = file.fileContentsPath;
	if (nil == fpath)
		Rc2LogError(@"not file with no path:%@", file);
	op.outputStream = [NSOutputStream outputStreamToFileAtPath:file.fileContentsPath append:NO];
	[_httpClient enqueueHTTPRequestOperation:op];
}

-(void)fetchBinaryFileContentsSynchronously:(RCFile*)file
{
	NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
	NSMutableURLRequest *req = [_httpClient requestWithMethod:@"GET" path:path parameters:nil];
	NSError *err=nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&err];
	if (err)
		Rc2LogError(@"error fetching sync file data (%@): %@", file.fileId, err);
	if (data) {
		[data writeToFile:file.fileContentsPath atomically:YES];
	}
}

-(NSString*)fetchFileContentsSynchronously:(RCFile*)file
{
	NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
	NSMutableURLRequest *req = [_httpClient requestWithMethod:@"GET" path:path parameters:nil];
	//AFNetworking doesn't support synchronous operations, so we use NSURLConnection once we have the request
	NSError *err=nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&err];
	if (err)
		Rc2LogError(@"error fetching sync file data (%@): %@", file.fileId, err);
	return [NSString stringWithUTF8Data:data];
}

//used by ios dropbox support
-(void)importFile:(NSURL*)fileUrl toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableString *path = [self containerPath:container];
	[path appendString:@"/file"];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:@{@"name":[fileUrl lastPathComponent]} constructingBodyWithBlock:^(id<AFMultipartFormData> fdata)
	{
		NSError *err=nil;
		if (![fdata appendPartWithFileURL:fileUrl name:@"contents" error:&err]) {
			Rc2LogError(@"failed to append file to upload request:%@", err);
			hblock(NO, [err localizedDescription]);
		}
	}];
	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id operation, id rsp) {
		if (0 == [[rsp objectForKey:@"status"] integerValue]) {
			NSDictionary *fdata = [[rsp objectForKey:@"files"] firstObject];
			RCFile *theFile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
			[theFile updateWithDictionary:fdata];
			[container addFile:theFile];
			hblock(YES, theFile);
		} else {
			Rc2LogWarn(@"status != 0 for file import:%@", [rsp objectForKey:@"message"]);
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		Rc2LogError(@"error uploading file sync:%@", error);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
}

//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl fileName:(NSString*)name toContainer:(id<RCFileContainer>)container error:(NSError *__autoreleasing *)outError
{
	NSMutableString *path = [self containerPath:container];
	[path appendString:@"/file"];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:@{@"name":name} constructingBodyWithBlock:^(id<AFMultipartFormData> fdata)
	{
		NSError *err=nil;
		if (![fdata appendPartWithFileURL:fileUrl name:@"contents" error:&err]) {
			Rc2LogError(@"failed to append file to upload request:%@", err);
		}
	}];
	[req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	__block NSMutableArray *outFiles = [[NSMutableArray alloc] init];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id operation, id rsp) {
		NSArray *fileArray = [rsp objectForKey:@"files"];
		for (NSDictionary *fdata in fileArray) {
			RCFile *theFile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
			[theFile updateWithDictionary:fdata];
			[container addFile:theFile];
			[outFiles addObject:theFile];
		}
	} failure:^(id op, NSError *error) {
		Rc2LogError(@"error uploading file sync:%@", error);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
	[op waitUntilFinished];
	return [outFiles firstObject];
}

-(void)importFiles:(NSArray*)urls toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
	progress:(void (^)(CGFloat))pblock
{
	NSMutableString *path = [self containerPath:container];
	[path appendString:@"/file"];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:nil
		constructingBodyWithBlock:^(id<AFMultipartFormData> fdata)
	{
		NSError *err=nil;
		for (NSURL *url in urls) {
			if (![fdata appendPartWithFileURL:url name:url.lastPathComponent error:&err])
				Rc2LogError(@"error on import:%@", err);
		}
	}];
	AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
	if (nil != pblock) {
		[op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
			pblock(totalBytesWritten/totalBytesExpectedToWrite);
		}];
	}
	[op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSDictionary *rsp = [[NSString stringWithUTF8Data:responseObject] JSONValue];
		if ([[rsp objectForKey:@"status"] integerValue] == 0) {
			NSArray *fs = [RCFile filesFromJsonArray:[rsp objectForKey:@"files"] container:container];
			for (RCFile *aFile in fs)
				[container addFile:aFile];
			hblock(YES, rsp);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
			Rc2LogWarn(@"error on import:%@", [rsp objectForKey:@"message"]);
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		hblock(NO, error.localizedDescription);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
}

-(void)saveFile:(RCFile*)file toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableString *path = [self containerPath:container];
	NSString *method = file.existsOnServer ? @"PUT" : @"POST";
	if (file.existsOnServer)
		[path appendFormat:@"/file/%@", file.fileId];
	else
		[path appendString:@"/file"];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:method path:path parameters:@{@"name":file.name}
												 constructingBodyWithBlock:^(id<AFMultipartFormData> fdata)
	{
		[fdata appendPartWithFormData:[file.currentContents dataUsingEncoding:NSUTF8StringEncoding] name:@"contents"];
	}];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id operation, id rsp) {
		if (0 == [[rsp objectForKey:@"status"] integerValue]) {
			if (file.existsOnServer) {
				NSString *oldContents = file.localEdits;
				[file updateWithDictionary:[rsp objectForKey:@"file"]];
				file.fileContents = oldContents;
				[file discardEdits];
				hblock(YES, file);
			} else {
				NSDictionary *fdata = [rsp objectForKey:@"file"];
				RCFile *rcfile = [RCFile insertInManagedObjectContext:[TheApp valueForKeyPath:@"delegate.managedObjectContext"]];
				[rcfile updateWithDictionary:fdata];
				[rcfile setValue:container forKey:@"container"];
				[container addFile:rcfile];
				[file.currentContents writeToFile:rcfile.fileContentsPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
				hblock(YES, rcfile);
			}
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id operation, NSError *error) {
		hblock(NO, error.localizedDescription);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
}

-(void)renameFile:(RCFile*)file toName:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableString *path = [self containerPath:file.container];
	[path appendFormat:@"/file/%@", file.fileId];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:@"PUT" path:path parameters:@{@"name":newName}
												 constructingBodyWithBlock:^(id<AFMultipartFormData> fdata)
	{
	}];
	AFHTTPRequestOperation *op = [_httpClient HTTPRequestOperationWithRequest:req success:^(id operation, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			[file updateWithDictionary:[rsp objectForKey:@"file"]];
			hblock(YES, file);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
	[_httpClient enqueueHTTPRequestOperation:op];
}

//synchronously update the content of a file
-(BOOL)updateFile:(RCFile*)file withContents:(NSURL*)contentsFileUrl workspace:(RCWorkspace*)workspace
			error:(NSError *__autoreleasing *)outError
{
	NSString *path = [NSString stringWithFormat:@"file/%@", file.fileId];
	NSMutableURLRequest *req = [_httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:nil
												 constructingBodyWithBlock:^(id <AFMultipartFormData>formData)
	{
		[formData appendPartWithFileURL:contentsFileUrl name:@"content" error:outError];
	}];
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:outError];
	if (nil == data) {
		Rc2LogError(@"error uploading file data (%@): %@", file.name, *outError);
		return NO;
	} else {
		NSDictionary *dict = [[NSString stringWithUTF8Data:data] JSONValue];
		[file discardEdits];
		[file updateWithDictionary:[dict objectForKey:@"file"]];
		if (file.isTextFile)
			file.fileContents = [NSString stringWithContentsOfURL:contentsFileUrl encoding:NSUTF8StringEncoding error:nil];
		return YES;
	}
}

-(void)deleteFile:(RCFile*)file container:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSMutableString *path = [self containerPath:container];
	[path appendFormat:@"/file/%@", file.fileId];
	[_httpClient deletePath:path parameters:nil success:^(id req, id rsp) {
		BOOL success = [[rsp objectForKey:@"status"] intValue] == 0;
		if (success)
			[container removeFile:file];
		hblock(success, rsp);
	} failure:^(id op, NSError *error) {
		hblock(NO, error.localizedDescription);
	}];
}

#pragma mark - notifications

-(void)requestNotifications:(Rc2FetchCompletionHandler)hblock
{
	return [self genericGetRequest:@"notify" parameters:nil handler:hblock];
}

-(void)deleteNotification:(NSNumber*)noteId completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient deletePath:[NSString stringWithFormat:@"notify/%@", noteId] parameters:nil success:^(AFHTTPRequestOperation *op, id rsp)
	{
		if (op.response.statusCode == 200)
			hblock(YES, rsp);
		else
			hblock(NO, [NSString stringWithFormat:@"delete failed with %@", @(op.response.statusCode)]);
	} failure:^(id op, NSError *err) {
		hblock(NO, err.localizedDescription);
	}];
}

#pragma mark - courses/assignments

-(BOOL)synchronouslyUpdateAssignment:(RCAssignment*)assignment withValues:(NSDictionary*)newVals
{
/*	ASIHTTPRequest *theReq = [self requestWithRelativeURL:[NSString stringWithFormat:@"courses/%@/assignment/%@",
							   assignment.course.classId, assignment.assignmentId]];
	[theReq addRequestHeader:@"Content-Type" value:@"application/json"];
	[theReq setRequestMethod:@"PUT"];
	[theReq appendPostData:[[newVals JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[theReq startSynchronous];
	if (200 != theReq.responseStatusCode)
		return NO;
	if ([[[[theReq responseString] JSONValue] objectForKey:@"status"] intValue] == 0)
		return YES; */
	return NO;
}

#pragma mark - messages

-(void)markMessageRead:(RCMessage*)message
{
/*	ASIHTTPRequest *req = [self requestWithRelativeURL:[NSString stringWithFormat:@"message/%@", message.rcptmsgId]];
	[req addRequestHeader:@"Content-Type" value:@"application/json"];
	[req appendPostData:[@"{}" dataUsingEncoding:NSUTF8StringEncoding]];
	req.requestMethod = @"PUT";
	
	[req startAsynchronous];
	message.dateRead = [NSDate date]; */
}

-(void)markMessageDeleted:(RCMessage*)message
{
/*	ASIHTTPRequest *req = [self requestWithRelativeURL:[NSString stringWithFormat:@"message/%@", message.rcptmsgId]];
	req.requestMethod = @"DELETE";
	[req startAsynchronous]; */
}

-(void)syncMessages:(Rc2FetchCompletionHandler)hblock
{
/*	ASIHTTPRequest *theReq = [self requestWithRelativeURL:@"messages"];
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
	[req startAsynchronous]; */
}

-(void)sendMessage:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient postPath:@"messages" parameters:params success:^(AFHTTPRequestOperation *op, id rsp) {
		if (op.response.statusCode == 200) {
			hblock(YES, rsp);
		} else {
			hblock(NO, @"unknown error");
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

#pragma mark - users

-(void)updateUserSettings:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient putPath:@"user" parameters:params success:^(AFHTTPRequestOperation *op, id rsp) {
		if (op.response.statusCode == 200) {
			hblock(YES, rsp);
		} else {
			hblock(NO, @"unknown error");
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)updateDeviceToken:(NSData*)token
{
	NSDictionary *params = @{@"token":[token hexidecimalString]};
	[_httpClient putPath:@"user" parameters:params success:^(AFHTTPRequestOperation *op, id rsp) {} failure:^(AFHTTPRequestOperation *op, NSError *err)
	{
		Rc2LogError(@"error updating device token:%@", err);
	}];
}

#pragma mark - admin

-(void)fetchRoles:(Rc2FetchCompletionHandler)hblock
{
	return [self genericGetRequest:@"role" parameters:nil handler:hblock];
}

-(void)fetchPermissions:(Rc2FetchCompletionHandler)hblock
{
	return [self genericGetRequest:@"perm" parameters:nil handler:hblock];
}

-(void)addPermission:(NSNumber*)permId toRole:(NSNumber*)roleId completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSDictionary *params = @{@"action":@"add", @"perm":permId, @"role":roleId};
	[_httpClient putPath:@"role" parameters:params success:^(id op, id rsp) {
		if ([[rsp objectForKey:@"status"] intValue] == 0) {
			hblock(YES, rsp);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)toggleRole:(NSNumber*)roleId user:(NSNumber*)userId
	completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSDictionary *args = @{@"userid":userId, @"roleid":roleId};
	[_httpClient postPath:@"admin/userrole" parameters:args success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			hblock(YES, rsp);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)searchUsers:(NSDictionary*)args completionHandler:(Rc2FetchCompletionHandler)hblock
{
	[_httpClient postPath:@"user" parameters:args success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			hblock(YES, rsp);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

-(void)addUser:(RCUser*)user password:(NSString*)password
	completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSDictionary *params = @{@"pass":password, @"email":user.email, @"login":user.login, @"name": user.name};
	[_httpClient postPath:@"proj" parameters:params success:^(id op, id rsp) {
		if (rsp && [[rsp objectForKey:@"status"] intValue] == 0) {
			self.projects = [RCProject projectsForJsonArray:[rsp objectForKey:@"projects"] includeAdmin:self.isAdmin];
			hblock(YES, rsp);
		} else {
			hblock(NO, [rsp objectForKey:@"message"]);
		}
	} failure:^(id op, NSError *error) {
		hblock(NO, [error localizedDescription]);
	}];
}

#pragma mark - login/logout

-(void)handleLoginResponse:(id)response forUser:(NSString*)user completionHandler:(Rc2FetchCompletionHandler)handler
{
	NSDictionary *rsp = [response JSONValue];
	if ([[rsp objectForKey:@"status"] intValue] != 0) {
		//error
		handler(NO, [rsp objectForKey:@"message"]);
	} else {
		//set to use json for everything else
		_httpClient.parameterEncoding = AFJSONParameterEncoding;
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
	//setup our client
	_httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:self.baseUrl]];
	[_httpClient setDefaultHeader:@"User-Agent" value:self.userAgentString];
	[_httpClient setDefaultHeader:@"Accept" value:@"application/json"];
	[_httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
	//perform the login
	NSMutableURLRequest *request = [_httpClient requestWithMethod:@"POST" path:@"login" parameters:@{@"login": user, @"password": password}];
	[request setTimeoutInterval:8];
	AFHTTPRequestOperation *rop = [_httpClient HTTPRequestOperationWithRequest:request success:^(id op, id response) {
		[[Rc2Server sharedInstance] handleLoginResponse:[op responseString] forUser:user completionHandler:hblock];
	} failure:^(id op, NSError *error) {
		Rc2LogError(@"login request failed:%@", error);
		NSString *msg = [NSString stringWithFormat:@"server returned %@", [error localizedDescription]];
		hblock(NO, msg);
	}];
	[_httpClient enqueueHTTPRequestOperation:rop];
}

-(void)logout
{
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
/*	NSArray *rcpts = [self.cachedData objectForKey:@"messageRecipients"];
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
	return [self handleMessageRcpts:[req.responseString JSONValue]]; */
	return nil;
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
