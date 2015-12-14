//
//  Rc2RestServer.h
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Rc2LoginSession;

typedef void (^Rc2RestCompletionHandler)(BOOL success, id results, NSError *error);

///posted on login and logout with the object being the Rc2RestServer instance
extern NSString * const Rc2RestLoginStatusChangedNotification;

@interface Rc2RestServer : NSObject
@property (nonatomic, strong, readonly) NSURLSession *urlSession;
@property (nonatomic, copy, readonly) NSArray<NSString*> *restHosts;
@property (nonatomic, copy, readonly) NSString *defaultRestHost;
@property (nonatomic, strong, readonly) Rc2LoginSession *loginSession;
@property (nonatomic, copy, readonly) NSString* connectionDescription;

+(instancetype)sharedInstance;
+(void)setSharedInstance:(Rc2RestServer*)server;

-(id)initWithSessionConfiguration:(NSURLSessionConfiguration*)config;

-(void)loginToHostName:(NSString*)hostName login:(NSString*)login password:(NSString*)password handler:(Rc2RestCompletionHandler)handler;

//updates the workspaces array of the loginSession
-(void)createWorkspace:(NSString*)wspaceName completionBlock:(Rc2RestCompletionHandler)handler;

@end
