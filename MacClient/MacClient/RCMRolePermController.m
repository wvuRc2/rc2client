//
//  RCMRolePermController.m
//  MacClient
//
//  Created by Mark Lilback on 2/6/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "RCMRolePermController.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

@interface RCMRolePermController()
-(void)fetchPermissions;
@end

@implementation RCMRolePermController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	[self fetchPermissions];
}

-(void)fetchPermissions
{
	ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:@"perm"];
	__unsafe_unretained ASIHTTPRequest *blockReq = req;
	req.completionBlock = ^{
		NSArray *perms = [blockReq.responseString JSONValue];
		self.permController.content = perms;
	};
	[req startAsynchronous];
}

@synthesize permTable;
@synthesize permController;
@end
