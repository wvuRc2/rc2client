//
//  RCSession.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocket07.h"

@class RCWorkspace;
@protocol RCSessionDelegate;
@class RCSavedSession;
@class RCFile;
@class RCSessionUser;

#define kMode_Share @"share"
#define kMode_Control @"control"
#define kMode_Classroom @"classroom"

@interface RCSession : NSObject<WebSocket07Delegate>
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

-(id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp;

//to be called on mac client because rsp in the init message is fake and needs to be updated later
-(void)updateWithServerResponse:(NSDictionary*)rsp;

-(void)startWebSocket;
-(void)closeWebSocket;

-(id)savedSessionState;

-(void)requestModeChange:(NSString*)newMode;
-(void)executeScript:(NSString*)script;
-(void)executeSweave:(NSString*)fname script:(NSString*)script;
-(void)sendChatMessage:(NSString*)message;
-(void)requestUserList;

-(void)raiseHand;
-(void)lowerHand;

-(id)settingForKey:(NSString*)key;
-(void)setSetting:(id)val forKey:(NSString*)key;
@end

@protocol RCSessionDelegate <NSObject>
-(void)connectionOpened;
-(void)connectionClosed;
-(void)handleWebSocketError:(NSError*)error;
-(void)processWebSocketMessage:(NSDictionary*)msg json:(NSString*)jsonString;
-(void)performConsoleAction:(NSString*)action;
-(void)displayImage:(NSString*)imgPath;
@end
