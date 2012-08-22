//
//  RCSession.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCWorkspace;
@protocol RCSessionDelegate;
@class RCSavedSession;
@class RCFile;
@class RCSessionUser;

#define kMode_Share @"share"
#define kMode_Control @"control"
#define kMode_Classroom @"classroom"

@interface RCSession : NSObject
@property (nonatomic, strong, readonly) RCWorkspace *workspace;
@property (nonatomic, unsafe_unretained) id<RCSessionDelegate> delegate;
@property (nonatomic, strong) NSNumber *userid;
@property (nonatomic, strong) RCFile *initialFileSelection;
@property (nonatomic, copy, readonly) NSArray *users;
@property (nonatomic, strong, readonly) RCSessionUser *currentUser;
@property (nonatomic, strong, readonly) NSString *mode;
@property (nonatomic, assign, readonly) BOOL socketOpen;
@property (nonatomic, assign, readonly) BOOL hasReadPerm;
@property (nonatomic, assign, readonly) BOOL hasWritePerm;
@property (assign) BOOL handRaised;
@property (assign) BOOL restrictedMode;
@property (nonatomic, readonly) BOOL isClassroomMode;

-(id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp;

//to be called on mac client because rsp in the init message is fake and needs to be updated later
-(void)updateWithServerResponse:(NSDictionary*)rsp;

-(void)startWebSocket;
-(void)closeWebSocket;

-(id)savedSessionState;

-(RCSessionUser*)userWithSid:(NSNumber*)sid;

-(void)requestModeChange:(NSString*)newMode;
-(void)executeScript:(NSString*)script scriptName:(NSString*)sname;
-(void)executeSweave:(NSString*)fname script:(NSString*)script;
-(void)executeSas:(RCFile*)file;
-(void)sendChatMessage:(NSString*)message;
-(void)requestUserList;

-(NSString*)escapeForJS:(NSString*)str;

-(void)raiseHand;
-(void)lowerHand;

-(void)sendAudioInput:(NSData*)data;

//for classroom mode
-(void)sendFileOpened:(RCFile*)file;

-(id)settingForKey:(NSString*)key;
-(void)setSetting:(id)val forKey:(NSString*)key;
@end

@protocol RCSessionDelegate <NSObject>
-(void)connectionOpened;
-(void)connectionClosed;
-(void)handleWebSocketError:(NSError*)error;
-(void)processWebSocketMessage:(NSDictionary*)msg json:(NSString*)jsonString;
-(void)processBinaryMessage:(NSData*)data;
-(void)performConsoleAction:(NSString*)action;
-(void)displayImage:(NSString*)imgPath;
-(void)displayEditorFile:(RCFile*)file;
-(void)displayLinkedFile:(NSString*)path;
-(void)workspaceFileUpdated:(RCFile*)file;
-(void)executeJavascript:(NSString*)js;
-(void)loadHelpURL:(NSURL*)url;
@end
