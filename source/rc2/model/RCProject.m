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
		NSArray *wspaces = [dict objectForKey:@"workspaces"];
		if (wspaces.count > 0) {
			NSMutableArray *a = [NSMutableArray arrayWithCapacity:wspaces.count];
			for (NSDictionary *d in wspaces) {
				RCWorkspace *wspace = [[Rc2Server sharedInstance] workspaceWithId:[d objectForKey:@"id"]];
				if (wspace)
					[a addObject:wspace];
			}
			self.workspaces = [a copy];
		}
	}
	return self;
}

-(BOOL)canDelete
{
	if ([_type isEqualToString:@"admin"] || [_type isEqualToString:@"class"])
		return NO;
	return YES;
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"RCProject: %@, (%d workspaces)", self.name, (int)_workspaces.count];
}

@end
