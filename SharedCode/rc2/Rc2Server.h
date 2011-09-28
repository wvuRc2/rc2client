//
//  Rc2Server.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;
@class RCWorkspaceFolder;
@class RCSession;
@class RCFile;
@class RCSavedSession;
@class RCMessage;

enum {
	eRc2Host_Harner=0,
	eRc2Host_Barney,
	eRc2Host_Local
};

typedef void (^Rc2SessionCompletionHandler)(BOOL success, NSString *message);
//results varies depending on the call
typedef void (^Rc2FetchCompletionHandler)(BOOL success, id results);

@interface Rc2Server : NSObject
+(Rc2Server*)sharedInstance;

@property (nonatomic, assign) NSInteger serverHost;
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, copy, readonly) NSString *currentLogin;
@property (nonatomic, copy, readonly) NSArray *workspaceItems;
@property (nonatomic, retain) RCWorkspace *selectedWorkspace;
@property (nonatomic, retain) RCSession *currentSession;

-(void)loginAsUser:(NSString*)user password:(NSString*)password 
 completionHandler:(Rc2SessionCompletionHandler)hbock;

-(void)logout;

-(NSString*)baseUrl;

-(id)savedSessionForWorkspace:(RCWorkspace*)workspace;

-(void)selecteWorkspaceWithId:(NSNumber*)wspaceId;

#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
-(void)syncMessages:(Rc2FetchCompletionHandler)hblock;
-(void)markMessageRead:(RCMessage*)message;
-(void)markMessageDeleted:(RCMessage*)message;
#endif

//results is tesponse dict from server with either workspace or error entry
-(void)addWorkspace:(NSString*)name parent:(RCWorkspaceFolder*)parent folder:(BOOL)isFolder
	completionHandler:(Rc2FetchCompletionHandler)hblock;

-(void)saveFile:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)deleteFile:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)prepareWorkspace:(Rc2FetchCompletionHandler)hblock;
-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock;

@end
