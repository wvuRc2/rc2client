//
//  Rc2Server.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;
@class RCWorkspaceFolder;
@class RCWorkspaceItem;
@class RCSession;
@class RCFile;
@class RCSavedSession;
@class RCMessage;
@class ASIHTTPRequest;
@class ASIFormDataRequest;
@class RCAssignment;

enum {
	eRc2Host_Rc2=0,
	eRc2Host_Barney,
	eRc2Host_Local
};

typedef void (^Rc2SessionCompletionHandler)(BOOL success, NSString *message);
//results varies depending on the call
typedef void (^Rc2FetchCompletionHandler)(BOOL success, id results);

extern NSString * const WorkspaceItemsChangedNotification;
//following is posted after all other login steps are complete
extern NSString * const NotificationsReceivedNotification;
//following is posted after messages are synced
extern NSString * const MessagesUpdatedNotification;

@interface Rc2Server : NSObject
#pragma mark - class methods
+(Rc2Server*)sharedInstance;

+(NSArray*)acceptableTextFileSuffixes;
+(NSArray*)acceptableImportFileSuffixes;
+(NSArray*)acceptableImageFileSuffixes;

#pragma mark - properties

@property (weak, nonatomic, readonly) NSString *userAgentString;
@property (nonatomic, assign) NSInteger serverHost;
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, copy, readonly) NSString *currentLogin;
@property (nonatomic, strong, readonly) NSNumber *currentUserId;
@property (nonatomic, copy) NSDictionary *userSettings;
@property (nonatomic, readonly) NSString *connectionDescription; //login name plus host if host is not rc2
@property (nonatomic, readonly) BOOL isAdmin;
@property (nonatomic, copy, readonly) NSArray *workspaceItems;
@property (nonatomic, copy, readonly) NSArray *usersPermissions;
@property (nonatomic, copy, readonly) NSArray *classesTaught;
@property (nonatomic, copy, readonly) NSArray *assignmentsToGrade;
@property (nonatomic, strong) RCWorkspace *selectedWorkspace;
@property (nonatomic, strong) RCSession *currentSession;
@property (nonatomic, strong, readonly) NSArray *messageRecipients;

#pragma mark - basic request operations
//this method should be called on any request being sent to the rc2 server
// it will set the user agent, appropriate security settings, and cookies
-(void)commonRequestSetup:(ASIHTTPRequest*)request;

//a convience method that calls commonRequestSetup
-(ASIHTTPRequest*)requestWithURL:(NSURL*)url;
-(ASIFormDataRequest*)postRequestWithURL:(NSURL*)url;
-(ASIHTTPRequest*)requestWithRelativeURL:(NSString*)urlString;
-(ASIFormDataRequest*)postRequestWithRelativeURL:(NSString*)urlString;

-(NSString*)baseUrl;
-(NSString*)websocketUrl;

-(BOOL)responseIsValidJSON:(ASIHTTPRequest*)request;

#pragma mark - login/logout
-(void)loginAsUser:(NSString*)user password:(NSString*)password 
 completionHandler:(Rc2FetchCompletionHandler)hbock;

-(void)logout;

#pragma mark - workspaces

-(id)savedSessionForWorkspace:(RCWorkspace*)workspace;

-(void)selectWorkspaceWithId:(NSNumber*)wspaceId;

//this will call block with every workspace, no matter how many folders it is nested in
-(void)enumerateWorkspacesWithBlock:(void (^)(RCWorkspace *wspace, BOOL *stop))block;

#pragma mark - messages
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
-(void)syncMessages:(Rc2FetchCompletionHandler)hblock;
-(void)markMessageRead:(RCMessage*)message;
-(void)markMessageDeleted:(RCMessage*)message;
#endif

#pragma mark - files
//results is tesponse dict from server with either workspace or error entry
-(void)addWorkspace:(NSString*)name parent:(RCWorkspaceFolder*)parent folder:(BOOL)isFolder
	completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)deleteWorkspce:(RCWorkspaceItem*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)renameWorkspce:(RCWorkspaceItem*)wspace name:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;

-(void)importFile:(NSURL*)fileUrl workspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;

-(void)saveFile:(RCFile*)file workspace:(RCWorkspace*)workspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)deleteFile:(RCFile*)file workspace:(RCWorkspace*)workspace completionHandler:(Rc2FetchCompletionHandler)hblock;

-(RCWorkspace*)workspaceForFile:(RCFile*)file;

//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl name:(NSString*)filename workspace:(RCWorkspace*)workspace error:(NSError *__autoreleasing *)outError;
//synchronously update the content of a file
-(BOOL)updateFile:(RCFile*)file withContents:(NSURL*)contentsFileUrl workspace:(RCWorkspace*)workspace  
			error:(NSError *__autoreleasing *)outError;

-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)fetchBinaryFileContents:(RCFile*)file toPath:(NSString*)destPath progress:(id)progressView
			 completionHandler:(Rc2FetchCompletionHandler)hblock;
-(NSString*)fetchFileContentsSynchronously:(RCFile*)file;
-(void)fetchBinaryFileContentsSynchronously:(RCFile*)file;

#pragma mark - preperation

-(void)prepareWorkspace:(Rc2FetchCompletionHandler)hblock; //prepares selected workspace
-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;

#pragma mark - courses/assignments

-(BOOL)synchronouslyUpdateAssignment:(RCAssignment*)assignment withValues:(NSDictionary*)newVals;

#pragma mark - misc/other

-(void)fetchWorkspaceShares:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(ASIHTTPRequest*)createUserSearchRequest:(NSString*)sstring searchType:(NSString*)searchType;
@end