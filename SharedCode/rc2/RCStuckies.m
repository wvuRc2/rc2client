//
//  RCStuckies.m
//  MacClient
//
//  Created by Mark Lilback on 1/30/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCStuckies.h"
#import "ASIFormDataRequest.h"

@implementation RCStuckies
-(NSString*)baseUrl
{
	return @"http://barney.stat.wvu.edu:9999/";
}

-(void)loginAsUser:(NSString*)user password:(NSString*)password completionHandler:(Rc2SessionCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@login", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
	NSDictionary *loginInfo = [NSDictionary dictionaryWithObjectsAndKeys:user, @"login", password, @"password", nil];
	[req setTimeOutSeconds:10];
	[req setPostValue:user forKey:@"login"];
	[req setPostValue:password forKey:@"password"];
	[req setCompletionBlock:^{
		[[Rc2Server sharedInstance] handleLoginResponse:req forUser:user completionHandler:hblock];
	}];
	[req setFailedBlock:^{
		NSString *msg = [NSString stringWithFormat:@"server returned %d", req.responseStatusCode];
		if (req.responseStatusCode == 0)
			msg = @"Server not responding";
		hblock(NO, msg);
	}];
	[req startAsynchronous];
}

@end
