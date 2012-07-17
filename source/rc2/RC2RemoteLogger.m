//
//  RC2RemoteLogger.m
//  iPadClient
//
//  Created by Mark Lilback on 9/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RC2RemoteLogger.h"
#import "ASIFormDataRequest.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "NSObject+SBJSON.h"
#endif

@interface RC2RemoteLogger() {
	NSString *versionStr;
}
-(NSData*)messageToJSONData:(DDLogMessage*)msg;
@end

@implementation RC2RemoteLogger

-(id)init
{
	self = [super init];
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	versionStr = [[NSString alloc] initWithFormat:@"%@/%@", 
				  [info objectForKey:@"CFBundleShortVersionString"],
				  [info objectForKey:@"CFBundleVersion"]];
	self.clientIdent = @"";
	return self;
}

-(void)logMessage:(DDLogMessage*)logMessage
{
	if (nil == self.logHost)
		return;
	ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:self.logHost];
	[req appendPostData:[self messageToJSONData:logMessage]];
	[req startAsynchronous];
}

-(NSData*)messageToJSONData:(DDLogMessage*)msg
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:self.apiKey forKey:@"apikey"];
	[dict setObject:[NSNumber numberWithInt:msg->logFlag] forKey:@"level"];
	[dict setObject:[NSNumber numberWithInt:msg->logContext] forKey:@"context"];
	[dict setObject:versionStr forKey:@"versionStr"];
	[dict setObject:self.clientIdent forKey:@"clientident"];
	[dict setObject:msg->logMsg forKey:@"message"];
	return [[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

@synthesize logHost;
@synthesize apiKey;
@synthesize clientIdent;
@end
