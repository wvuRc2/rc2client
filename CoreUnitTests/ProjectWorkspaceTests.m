//
//  ProjectWorkspaceTests.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RCProject.h"

@interface ProjectWorkspaceTests : SenTestCase
@property (nonatomic, strong) NSData *testJson;
@end

@implementation ProjectWorkspaceTests

-(void)setUp
{
	NSURL *json = [[NSBundle bundleForClass:[self class]] URLForResource:@"projwspaceJson" withExtension:@"txt"];
	self.testJson = [NSData dataWithContentsOfURL:json];
	STAssertNotNil(self.testJson, @"failed to load json to test with");
}

-(void)testProjects
{
	NSError *err=nil;
	NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.testJson options:0 error:&err];
	STAssertNotNil(jsonDict, @"failed to parse test json:%@", err);
	NSArray *projects = [RCProject projectsForJsonArray:[jsonDict objectForKey:@"projects"] includeAdmin:NO];
	STAssertEquals(projects.count, 1, @"inaccruate number of projects:%d", projects.count);
	STAssertEqualObjects(@"Cornocopia", [projects[0] objectForKey:@"name"], @"incorrect project name");
}

@end
