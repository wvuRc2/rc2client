//
//  RCActiveLogin.m
//  Rc2Client
//
//  Created by Mark Lilback on 7/31/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import "RCActiveLogin.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "RCUser.h"

@interface RCActiveLogin ()
@property (nonatomic, strong, readwrite) RCUser *currentUser;
@property (nonatomic, copy, readwrite) NSArray *usersPermissions;
@property (nonatomic, copy, readwrite) NSArray *ldapServers;
@property (nonatomic, copy, readwrite) NSArray *classesTaught;
@property (nonatomic, copy, readwrite) NSArray *assignmentsToGrade;
@property (nonatomic, strong, readwrite) NSArray *messageRecipients;
@end

@implementation RCActiveLogin

-(instancetype)initWithJsonData:(NSDictionary *)json
{
	if (self = [super init]) {
		self.currentUser = [[RCUser alloc] initWithDictionary:json[@"user"] allRoles:json[@"roles"]];
		self.usersPermissions = json[@"permissions"];
		self.ldapServers = json[@"ldapServers"];
//		[self.cachedData setObject:[RCCourse classesFromJSONArray:json[@"classes"]] forKey:@"classesTaught"];
		self.assignmentsToGrade = json[@"tograde"];
		self.projects = [RCProject projectsForJsonArray:json[@"projects"] includeAdmin:self.isAdmin];
	}
	return self;
}

-(RCWorkspace*)workspaceWithId:(NSNumber*)wspaceId
{
	for (RCProject *project in self.projects) {
		for (RCWorkspace *wspace in project.workspaces) {
			if ([wspace.wspaceId isEqualToNumber:wspaceId])
				return wspace;
		}
	}
	return nil;
}


@end
