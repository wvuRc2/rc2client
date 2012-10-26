//
//  RCProject.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCProject.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"

@interface RCProject ()
@property (nonatomic, strong, readwrite) NSArray *workspaces;
@property (nonatomic, strong, readwrite) NSArray *subprojects;
@end

@implementation RCProject

+(NSArray*)projectsForJsonArray:(NSArray*)jsonArray includeAdmin:(BOOL)admin
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:jsonArray.count + 1];
	if (admin) {
		[a addObject:[[RCProject alloc] initWithDictionary:@{@"name":@"Admin",@"id":@-2,@"type":@"admin"}]];
	}
	for (NSDictionary *d in jsonArray)
		[a addObject:[[RCProject alloc] initWithDictionary:d]];
	return a;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.projectId = [dict objectForKey:@"id"];
		self.name = [dict objectForKey:@"name"];
		if ([[dict objectForKey:@"type"] isKindOfClass:[NSString class]])
			self.type = [dict objectForKey:@"type"];
		NSArray *dictProjs = [dict objectForKey:@"projects"];
		if (dictProjs.count > 0) {
			NSMutableArray *a = [NSMutableArray arrayWithCapacity:dictProjs.count];
			for (NSDictionary *d  in dictProjs) {
				RCProject *subp = [[RCProject alloc] initWithDictionary:d];
				subp.parentProject = self;
				[a addObject:subp];
			}
			self.subprojects = [a copy];
		}
	NSArray *wspaces = [dict objectForKey:@"workspaces"];
	if (wspaces.count > 0) {
		NSMutableArray *a = [NSMutableArray arrayWithCapacity:wspaces.count];
		for (NSDictionary *d in wspaces) {
			RCWorkspace *wspace = [[[Rc2Server sharedInstance] workspaceItems] firstObjectWithValue:[d objectForKey:@"id"] forKey:@"wspaceId"];
			if (wspace)
				[a addObject:wspace];
		}
		self.workspaces = [a copy];
	}
	}
	return self;
}

@end
