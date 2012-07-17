//
//  RCAudioChatEngine.h
//  iPadClient
//
//  Created by Mark Lilback on 3/2/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCSession;

@interface RCAudioChatEngine : NSObject
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, readonly) BOOL mikeOn;

-(void)tearDownAudio;
-(void)processBinaryMessage:(NSData*)data;
-(void)toggleMicrophone;

//for debugging purposes
-(void)playDataFromFile:(NSString*)filePath;
@end
