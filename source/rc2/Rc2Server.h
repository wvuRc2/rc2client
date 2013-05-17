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

enum {
	eRc2Host_Rc2=0,
	eRc2Host_Barney,
	eRc2Host_Local
};

//results varies depending on the call
typedef void (^Rc2FetchCompletionHandler)(BOOL success, id results);

extern NSString * const WorkspaceItemsChangedNotification;
//following is posted after all other login steps are complete
extern NSString * const NotificationsReceivedNotification;
//following is posted after messages are synced
extern NSString * const MessagesUpdatedNotification;
//posted after files are added to a FileContainer. object is the workspace/project
extern NSString * const FilesChagedNotification;

@interface Rc2Server : NSObject
#pragma mark - class methods
+(Rc2Server*)sharedInstance;

+(NSArray*)acceptableTextFileSuffixes;
+(NSArray*)acceptableImportFileSuffixes;
+(NSArray*)acceptableImageFileSuffixes;

#pragma mark - properties

@property (nonatomic, strong, readonly) AFHTTPClient *httpClient;
@property (weak, nonatomic, readonly) NSString *userAgentString;
@property (nonatomic, assign) NSInteger serverHost;
@property (nonatomic, assign, readonly) BOOL loggedIn;
@property (nonatomic, copy, readonly) NSString *currentLogin;
@property (nonatomic, strong, readonly) NSNumber *currentUserId;
@property (nonatomic, copy) NSDictionary *userSettings;
@property (nonatomic, readonly) NSString *connectionDescription; //login name plus host if host is not rc2
@property (nonatomic, readonly) BOOL isAdmin;
@property (nonatomic, copy, readonly) NSArray *projects;
@property (nonatomic, copy, readonly) NSArray *usersPermissions;
@property (nonatomic, copy, readonly) NSArray *ldapServers;
@property (nonatomic, copy, readonly) NSArray *classesTaught;
@property (nonatomic, copy, readonly) NSArray *assignmentsToGrade;
@property (nonatomic, strong, readonly) NSArray *messageRecipients;

-(NSString*)websocketUrl;

#pragma mark - login/logout
-(void)loginAsUser:(NSString*)user password:(NSString*)password 
 completionHandler:(Rc2FetchCompletionHandler)hbock;

-(void)logout;

#pragma mark - projects

//projects array is updated and hblock called with the new project
-(void)createProject:(NSString*)projectName completionBlock:(Rc2FetchCompletionHandler)hblock;
//updates project with the new name on success
-(void)editProject:(RCProject*)project newName:(NSString*)newName completionBlock:(Rc2FetchCompletionHandler)hblock;
//will remove it from projects array before hblock called
-(void)deleteProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock;

#pragma mark - workspaces

//updates the project object, calls hblock with the new workspace
-(void)createWorkspace:(NSString*)projectName inProject:(RCProject*)project completionBlock:(Rc2FetchCompletionHandler)hblock;


-(id)savedSessionForWorkspace:(RCWorkspace*)workspace;


-(void)prepareWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;

//convience method used when ipad restores the last open session
-(RCWorkspace*)workspaceWithId:(NSNumber*)wspaceId;

#pragma mark - messages
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#else
-(void)syncMessages:(Rc2FetchCompletionHandler)hblock;
-(void)markMessageRead:(RCMessage*)message;
-(void)markMessageDeleted:(RCMessage*)message;
-(void)sendMessage:(NSDictionary*)params completionHandler:(Rc2FetchCompletionHandler)hblock;
#endif

//results is tesponse dict from server with either workspace or error entry
-(void)deleteWorkspce:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)renameWorkspce:(RCWorkspace*)wspace name:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;
-(void)refereshWorkspace:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock;

#pragma mark - files
-(void)importFile:(NSURL*)fileUrl toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock;
//synchronously imports the file, adds it to the workspace, and returns the new RCFile object.
-(RCFile*)importFile:(NSURL*)fileUrl fileName:(NSString*)name toContainer:(id<RCFileContainer>)dest error:(NSError *__autoreleasing *)outError;


//imports multiple files
-(void)importFiles:(NSArray*)urls toContainer:(id<RCFileContainer>)container completionHandler:(Rc2FetchCompletionHandler)hblock
		  progress:(void (^)(CGFloat))pblock;


-(void)renameFile:(RCFile*)file toName:(NSString*)newName completionHandler:(Rc2FetchCompletionHandler)hblock;

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
