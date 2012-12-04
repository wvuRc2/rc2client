//
//  RCAssignmentFile.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/2/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCAssignmentFile.h"

@interface RCAssignmentFile()
@property (nonatomic, copy) NSDictionary *properties;
@end

@implementation RCAssignmentFile

+(NSArray*)filesFromJSONArray:(NSArray*)json forCourse:(RCAssignment*)assignment
{
	NSMutableArray *a = [NSMutableArray array];
	for (NSDictionary *d in json) {
		RCAssignmentFile *file = [[RCAssignmentFile alloc] initWithDictionary:d];
		file.assignment = assignment;
		[a addObject:file];
	}
	return a;
}

-(id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	[self updateWithDictionary:dict];
	return self;
}

-(void)updateWithDictionary:(NSDictionary*)dict
{
	self.name = [dict valueForKeyPath:@"file.name"];
	self.readonly = [[dict objectForKey:@"readonly"] boolValue];
	self.properties = dict;
}

-(NSNumber*)assignmentFileId
{
	return [self.properties objectForKey:@"id"];
}

@synthesize properties=_properties;
@synthesize name=_name;
@synthesize readonly=_readonly;
@synthesize assignment=_assignment;
@end
