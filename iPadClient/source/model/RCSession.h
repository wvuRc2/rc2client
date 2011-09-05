//
//  RCSession.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocket00.h"

@class RCWorkspace;
@protocol RCSessionDelegate;
@class RCSavedSession;

@interface RCSession : NSObject<WebSocket00Delegate>
@property (nonatomic, retain, readonly) RCWorkspace *workspace;
@property (nonatomic, assign) id<RCSessionDelegate> delegate;
@property (nonatomic, retain) NSNumber *userid;
@property (nonatomic, assign, readonly) BOOL socketOpen;
@property (nonatomic, assign, readonly) BOOL hasReadPerm;
@property (nonatomic, assign, readonly) BOOL hasWritePerm;

-(id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp;

-(void)startWebSocket;
-(void)closeWebSocket;

-(RCSavedSession*)savedSessionState;

-(void)executeScript:(NSString*)script;
-(void)sendChatMessage:(NSString*)message;

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
