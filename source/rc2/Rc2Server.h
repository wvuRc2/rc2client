//
//  Rc2Server.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "RCFileContainer.h"

@class RCWorkspace;
@class RCWorkspaceFolder;
@class RCWorkspaceItem;
@class RCSession;
@class RCFile;
@class RCUser;
@class RCSavedSession;
@class RCMessage;
@class RCAssignment;
@class RCProject;
@class RCActiveLogin;
@protocol Rc2Server;

enum {
	eRc2Host_Rc2=0,
	eRc2Host_Barney,
	eRc2Host_Local
};

//results varies depending on the call
typedef void (^Rc2FetchCompletionHandler)(BOOL success, id results);

//following is posted after all other login steps are complete
extern NSString * const RC2NotificationsReceivedNotification;
//following is posted after messages are synced
extern NSString * const RC2MessagesUpdatedNotification;
//posted when a file has been deleted on the server (via this or any other client). object is the file.
extern NSString * const RC2FileDeletedNotification;

id<Rc2Server> RC2_SharedInstance();
NSArray* RC2_AcceptableTextFileSuffixes();
NSArray* RC2_AcceptableImportFileSuffixes();


@protocol Rc2Server <NSObject>

#pragma mark - properties

@property (nonatomic, strong, readonly) RCActiveLogin *activeLogin;

@property (nonatomic, strong, readonly) AFHTTPClient *httpClient;
@property (weak, nonatomic, readonly) NSString *userAgentString;
@property (nonatomic, assign) NSInteger serverHost;
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, readonly) NSString *connectionDescription; //login name plus host if host is not rc2

-(NSString*)websocketUrl;

#pragma mark - login/logout
-(void)loginAsUser:(NSString*)user password:(NSString*)password 
 completionHandler:(Rc2FetchCompletionHandler)hbock;

-(void)logout;

#pragma mark - projects

//*HAS TEST* projects array is updated and hblock called with a dict containg keys for "projects" and "newProject"
-(void)createProject:(NSString*)projectName completionBlock:(Rc2FetchCompletionHandler)hblock;
//*HAS TEST* updates project with the new name on success
-(void)editProject:(RCProject*)project newName:(NSString*)newName completionBlock:(Rc2FetchCompletionHandler)hblock;
//*HAS TEST* will remove it from projects array before hblock called
-(void)deleteProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock;

//return array of user dicts
-(void)sharesForProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock;
//share a project with a user
-(void)shareProject:(RCProject*)project userId:(NSNumber*)userId completionBlock:(Rc2FetchCompletionHandler)hblock;
//stop sharing of a project with a user
-(void)unshareProject:(RCProject*)project userId:(NSNumber*)userId completionBlock:(Rc2FetchCompletionHandler)hblock;

#pragma mark - workspaces

//*HAS TEST* updates the project object, calls hblock with the new workspace
-(void)createWorkspace:(NSString*)projectName inProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock;
//this is for dropbox sync only
-(void)updateWorkspace:(RCWorkspace*)wspace completionBlock:(Rc2FetchCompletionHandler)hblock;
//*HAS TEST* results is tesponse dict from server with either workspace or error entry
-(void)deleteWorkspce:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
//*HAS TEST*
-(void)renameWorkspce:(RCWorkspace*)wspace name:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;

//this is for internal use of the RCWorkspace class which handles the json parsing
-(void)refereshWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)updateWorkspaceShare:(RCWorkspace*)wspace perm:(NSString*)sharPerm completionHandler:(Rc2FetchCompletionHandler)hblock;

//looks up a saved session from local storage for workspace
-(id)savedSessionForWorkspace:(RCWorkspace*)workspace;

//*HAS TEST* checks to see if user has permission to use the workspace, server also sets wspaceid cookie
-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;


#pragma mark - messages
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
-(void)syncMessages:(Rc2FetchCompletionHandler)hblock;
-(void)markMessageRead:(RCMessage*)message;
-(void)markMessageDeleted:(RCMessage*)message;
-(void)sendMessage:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock;
#endif


#pragma mark - files
-(void)importFile:(NSURL*)fileUrl toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock;
//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl fileName:(NSString*)name toContainer:(id<RCFileContainer>)dest error:(NSError *__autoreleasing *)outError;


//*HAS TEST* imports multiple files
-(void)importFiles:(NSArray*)urls toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
		  progress:(void (^)(CGFloat))pblock;


-(void)renameFile:(RCFile*)file toName:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;

//*HAS TEST*
-(void)deleteFile:(RCFile*)file container:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock;

-(void)fetchFileContents:(RCFile*)file completionHandler:(Rc2FetchCompletionHandler)hblock;
-(NSString*)fetchFileContentsSynchronously:(RCFile*)file;
-(void)fetchBinaryFileContentsSynchronously:(RCFile*)file;

-(void)saveFile:(RCFile*)file toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock;
//synchronously update the content of a file
-(BOOL)updateFile:(RCFile*)file withContents:(NSURL*)contentsFileUrl workspace:(RCWorkspace*)workspace
			error:(NSError *__autoreleasing *)outError;

//ask to have a file removed from objects/core ddata when the server has said via websocket that it was deleted
-(void)removeFileReferences:(RCFile*)file;

#pragma mark - notifications

//the results will be a string if failed, a dictionary if successful
-(void)requestNotifications:(Rc2FetchCompletionHandler)hblock;

-(void)deleteNotification:(NSNumber*)noteId completionHandler:(Rc2FetchCompletionHandler)hblock;

#pragma mark - courses/assignments

-(BOOL)synchronouslyUpdateAssignment:(RCAssignment*)assignment withValues:(NSDictionary*)newVals;

#pragma mark - admin

-(void)fetchRoles:(Rc2FetchCompletionHandler)hblock;
-(void)fetchPermissions:(Rc2FetchCompletionHandler)hblock;
-(void)addPermission:(NSNumber*)permId toRole:(NSNumber*)roleId completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)searchUsers:(NSDictionary*)args completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)addUser:(RCUser*)user password:(NSString*)password completionHandler:(Rc2FetchCompletionHandler)handler;
-(void)importUsers:(NSURL*)fileUrl completionHandler:(Rc2FetchCompletionHandler)handler;
-(void)saveUserEdits:(RCUser*)user completionHandler:(Rc2FetchCompletionHandler)hblock; //if fails, caller is responsible for reverting RCUser
-(void)toggleRole:(NSNumber*)roleId user:(NSNumber*)userId
	completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)fetchCourses:(Rc2FetchCompletionHandler)hblock;
-(void)fetchCourseStudents:(NSNumber*)courseId completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)addCourse:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)addStudent:(NSNumber*)userId toCourse:(NSNumber*)courseId completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)removeStudent:(NSNumber*)userId fromCourse:(NSNumber*)courseId completionHandler:(Rc2FetchCompletionHandler)hblock;

#pragma mark - misc/other

-(void)updateDeviceToken:(NSData*)token;

-(void)updateUserSettings:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock;

-(void)downloadAppPath:(NSString*)path toFilePath:(NSString*)filePath completionHandler:(Rc2FetchCompletionHandler)hblock;

@end
