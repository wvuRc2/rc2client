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
@class Rc2FileType;
@class RCImage;
@class RCSessionUser;

extern NSString * const RC2WebSocketErrorDomain;

enum {
	kRc2Err_Unknown=-1,
	kRc2Err_ConnectionTimedOut=1
};

#define kMode_Share @"share"
#define kMode_Control @"control"
#define kMode_Classroom @"classroom"

typedef NS_OPTIONS(NSUInteger, RCSessionExecuteOptions) {
	RCSessionExecuteOptionNone,
	RCSessionExecuteOptionSource
};

@interface RCSession : NSObject
@property (nonatomic, strong, readonly) RCWorkspace *workspace;
@property (nonatomic, unsafe_unretained) id<RCSessionDelegate> delegate;
@property (nonatomic, strong) NSNumber *userid;
@property (nonatomic, strong) RCFile *initialFileSelection;
@property (nonatomic, copy, readonly) NSArray *variables;
@property (nonatomic, copy, readonly) NSArray *users;
@property (nonatomic, strong, readonly) RCSessionUser *currentUser;
@property (nonatomic, strong, readonly) NSString *mode;
@property (nonatomic, assign, readonly) BOOL socketOpen;
@property (nonatomic, assign, readonly) BOOL hasReadPerm;
@property (nonatomic, assign, readonly) BOOL hasWritePerm;
@property (assign) BOOL handRaised;
@property (assign) BOOL restrictedMode;
@property (nonatomic) BOOL variablesVisible;
@property (nonatomic, readonly) BOOL isClassroomMode;
@property (assign) BOOL showResultDetails;

-(id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp;

//to be called on mac client because rsp in the init message is fake and needs to be updated later
-(void)updateWithServerResponse:(NSDictionary*)rsp;

-(void)startWebSocket;
-(void)closeWebSocket;

-(id)savedSessionState;

-(RCSessionUser*)userWithSid:(NSNumber*)sid;

-(void)requestModeChange:(NSString*)newMode;
-(void)executeScript:(NSString*)script scriptName:(NSString*)sname options:(RCSessionExecuteOptions)options;
-(void)executeScript:(NSString*)script scriptName:(NSString*)sname;
-(void)executeScriptFile:(RCFile*)file options:(RCSessionExecuteOptions)options;
-(void)executeScriptFile:(RCFile*)file;
-(void)executeSas:(RCFile*)file;
-(void)sendChatMessage:(NSString*)message;
-(void)requestUserList;
-(void)restartR;

-(NSString*)escapeForJS:(NSString*)str;

-(void)raiseHand;
-(void)lowerHand;

-(void)clearVariables;
-(void)forceVariableRefresh;

-(void)sendAudioInput:(NSData*)data;

-(BOOL)fileCanBePromotedToAssignment:(RCFile*)file;

//for classroom mode
-(void)sendFileOpened:(RCFile*)file fullscreen:(BOOL)fs;

-(id)settingForKey:(NSString*)key;
-(void)setSetting:(id)val forKey:(NSString*)key;
@end

@protocol RCSessionDelegate <NSObject>
-(void)connectionOpened;
-(void)connectionClosed;
-(void)handleWebSocketError:(NSError*)error;
-(void)appendAttributedString:(NSAttributedString*)aString;
-(void)processWebSocketMessage:(NSDictionary*)msg json:(NSString*)jsonString;
-(void)processBinaryMessage:(NSData*)data;
-(void)displayImage:(RCImage*)image fromGroup:(NSArray*)imgGroup;
-(void)displayEditorFile:(RCFile*)file;
-(void)displayLinkedFile:(NSString*)path;
-(void)workspaceFileUpdated:(RCFile*)file deleted:(BOOL)deleted;
-(void)loadHelpURL:(NSURL*)url;
-(void)variablesUpdated;
-(NSTextAttachment*)textAttachmentForImageId:(NSNumber*)imgId imageUrl:(NSString*)imgUrl;
-(NSTextAttachment*)textAttachmentForFileId:(NSNumber*)fileId name:(NSString*)fileName fileType:(Rc2FileType*)fileType;
-(BOOL)textAttachmentIsImage:(NSTextAttachment*)tattach;
@end
