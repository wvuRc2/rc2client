//
//  RCLoginSession.m
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import "RCLoginSession.h"
#import "RCWorkspace.h"
#import "Rc2-Swift.h"

@interface RCLoginSession ()
@property (nonatomic, strong, readwrite) Rc2User *currentUser;
@property (nonatomic, copy, readwrite) NSString *authToken;
@end

@implementation RCLoginSession

-(instancetype)initWithJsonData:(NSDictionary *)json
{
	if (self = [super init]) {
		self.currentUser = [[Rc2User alloc] initWithJsonData:json[@"user"]];
		self.authToken = json[@"token"];
		self.workspaces = [Rc2Workspace workspacesFromJsonArray:json[@"workspaces"]];
	}
	return self;
}

-(RCWorkspace*)workspaceWithId:(NSNumber*)wspaceId
{
	for (RCWorkspace *wspace in self.workspaces) {
		if ([wspace.wspaceId isEqualToNumber:wspaceId])
			return wspace;
	}
	return nil;
}

@end
