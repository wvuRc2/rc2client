//
//  RCStuckies.m
//  MacClient
//
//  Created by Mark Lilback on 1/30/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCStuckies.h"
#import "ASIFormDataRequest.h"
#import "RCWorkspace.h"
#import "RCWorkspaceShare.h"

@implementation RCStuckies
-(NSString*)baseUrl
{
	return @"http://barney.stat.wvu.edu:9999/";
}

-(void)fetchFileList:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@fd/ftree/%@", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		NSMutableArray *entries = [NSMutableArray arrayWithArray:[rsp objectForKey:@"files"]];
		//now we need to add any local files that haven't been sent to the server
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		NSSet *newFiles = [moc fetchObjectsForEntityName:@"RCFile" withPredicate:@"fileId == 0 and wspaceId == %@",
						   self.selectedWorkspace.wspaceId];
		[entries addObjectsFromArray:[newFiles allObjects]];
		hblock(![[rsp objectForKey:@"status"] boolValue], entries);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)fetchWorkspaceShares:(RCWorkspace*)wspace completionHandler:(Rc2FetchCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@workspace/%@/share", [self baseUrl],
									   wspace.wspaceId]];
	ASIHTTPRequest *theReq = [self requestWithURL:url];
	__weak ASIHTTPRequest *req = theReq;
	[req setCompletionBlock:^{
		NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
		if (![self responseIsValidJSON:req]) {
			hblock(NO, @"server sent back invalid response");
			return;
		}
		NSDictionary *rsp = [respStr JSONValue];
		[wspace.shares removeAllObjects];
		for (NSDictionary *dict in [rsp objectForKey:@"shares"]) {
			RCWorkspaceShare *share = [[RCWorkspaceShare alloc] initWithDictionary:dict workspace:wspace];
			[wspace.shares addObject:share];
		}
		hblock(![[rsp objectForKey:@"status"] boolValue], wspace.shares);
	}];
	[req setFailedBlock:^{
		hblock(NO, [NSString stringWithFormat:@"server returned %d", req.responseStatusCode]);
	}];
	[req startAsynchronous];
}

-(void)loginAsUser:(NSString*)user password:(NSString*)password completionHandler:(Rc2SessionCompletionHandler)hblock
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@login", [self baseUrl]]];
	ASIFormDataRequest *theReq = [self postRequestWithURL:url];
	__weak ASIFormDataRequest *req = theReq;
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
