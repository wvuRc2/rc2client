//
//  RC2RemoteLogger.m
//  iPadClient
//
//  Created by Mark Lilback on 9/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RC2RemoteLogger.h"
#import "AFNetworking.h"
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
	//fire and forget a message to the server
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:self.logHost];
	NSData *data = [self messageToJSONData:logMessage];
	[req setHTTPMethod:@"POST"];
	[req setValue:@"application/json" forHTTPHeaderField:@"Acept"];
	[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[req setValue:[NSString stringWithFormat:@"%ld", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
	[req setHTTPBody:data];
	[NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *r, NSData *d, NSError *e) {
	}];
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

@end
