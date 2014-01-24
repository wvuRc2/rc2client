//
//  ProjectWorkspaceTests.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RCProject.h"

@interface ProjectWorkspaceTests : XCTestCase
@property (nonatomic, strong) NSData *testJson;
@end

@implementation ProjectWorkspaceTests

-(void)setUp
{
	NSURL *json = [[NSBundle bundleForClass:[self class]] URLForResource:@"projwspaceJson" withExtension:@"txt"];
	self.testJson = [NSData dataWithContentsOfURL:json];
	XCTAssertNotNil(self.testJson, @"failed to load json to test with");
}

-(void)testProjects
{
	NSError *err=nil;
	NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.testJson options:0 error:&err];
	XCTAssertNotNil(jsonDict, @"failed to parse test json:%@", err);
	NSArray *projects = [RCProject projectsForJsonArray:[jsonDict objectForKey:@"projects"] includeAdmin:NO];
	XCTAssertTrue(projects.count == 1, @"inaccruate number of projects:%ld", (long)projects.count);
	XCTAssertEqualObjects(@"Cornocopia", [projects[0] name], @"incorrect project name");
}

@end
