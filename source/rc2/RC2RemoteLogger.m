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
				  info[@"CFBundleShortVersionString"],
				  info[@"CFBundleVersion"]];
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
	[NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *rresp, NSData *data, NSError *error) {
	}];
}

-(NSData*)messageToJSONData:(DDLogMessage*)msg
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:self.apiKey forKey:@"apikey"];
	dict[@"level"] = @(msg->_level);
	dict[@"context"] = @(msg->_context);
	dict[@"versionStr"] = versionStr;
	dict[@"clientident"] = self.clientIdent;
	dict[@"message"] = msg->_message;
	return [[dict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
