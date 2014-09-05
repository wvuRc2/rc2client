
//
//  Rc2ServerTests.m
//  RestTests
//
//  Created by Mark Lilback on 8/29/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Rc2Server.h"
#import "RCActiveLogin.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import <Vyana/Vyana.h>

@interface RestTests : XCTestCase
@end

@implementation RestTests

- (void)setUp
{
	[super setUp];
	id<Rc2Server> server = RC2_SharedInstance();
	if (![server loggedIn]) {
		[self keyValueObservingExpectationForObject:server keyPath:@"loggedIn" expectedValue:@YES];
		[self waitForExpectationsWithTimeout:3 handler:^(NSError *error) {
			XCTAssertTrue(server.loggedIn, @"failed to login");
			NSLog(@"logged in");
		}];
	}
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

-(void)testDefaultWorkspace
{
	id<Rc2Server> server = RC2_SharedInstance();
	NSArray *projects = [[server activeLogin] projects];
	__block RCProject *project;
	[projects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([[obj name] isEqualToString:@"foofy"]) {
			project = obj;
			*stop = YES;
		}
	}];
	XCTAssertNotNil(project, @"failed to find foofy project");
	NSPredicate *thricePredicate = [NSPredicate predicateWithFormat:@"name = 'thrice'"];
	RCWorkspace *wspace = [[project.workspaces filteredArrayUsingPredicate:thricePredicate] firstObject];
	XCTAssertNotNil(wspace, @"failed to find thrice");
}

-(void)testCreateWorkspace
{
	NSString *const projectName = @"unitTestP";
	NSString *const editedName = @"unitTestPEdited";
	NSString *const wspaceName = @"testws";
	NSString *const wspaceEditedName = @"testws-edit";
	
	id<Rc2Server> server = RC2_SharedInstance();
	NSArray *projects = [[server activeLogin] projects];
	__block RCProject *project = [projects firstObjectWithValue:projectName forKey:@"name"];
	//if there is an old project, delete it
	if (project) {
		XCTestExpectation *oldDelExpect = [self expectationWithDescription:@"delete old project"];
		[server deleteProject:project completionBlock:^(BOOL success, id results) {
			XCTAssertTrue(success, @"Failed to delete old project: %@", results);
			[oldDelExpect fulfill];
		}];
		[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];
	}
	//create a project
	XCTestExpectation *projCreateExpect = [self expectationWithDescription:@"create project"];
	[server createProject:projectName completionBlock:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to create project: %@", results);
		XCTAssertEqualObjects(server.activeLogin.projects, results[@"projects"], @"projects not set properly");
		project = [results objectForKey:@"newProject"];
		[projCreateExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//edit name of project
	XCTestExpectation *projEditExpect = [self expectationWithDescription:@"edit project"];
	[server editProject:project newName:editedName completionBlock:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to edit project: %@", results);
		XCTAssertEqualObjects(editedName, project.name, @"project name not edited");
		[projEditExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//create a workspace
	__block RCWorkspace *wspace;
	XCTestExpectation *createWorkExpect = [self expectationWithDescription:@"create workspace"];
	[server createWorkspace:wspaceName inProject:project completionBlock:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to create workspace: %@", results);
		wspace = results;
		XCTAssertEqualObjects(wspaceName, wspace.name, @"created workspace name incorrect");
		[createWorkExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//edit workspace name
	XCTestExpectation *editWorkExpect = [self expectationWithDescription:@"edit workspace"];
	[server renameWorkspce:wspace name:wspaceEditedName completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to edit workspace: %@", results);
		XCTAssertEqualObjects(wspaceEditedName, wspace.name, @"edited workspace name incorrect");
		[editWorkExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//prepare workspace
	XCTestExpectation *useExpect = [self expectationWithDescription:@"use workspace"];
	[server prepareWorkspace:wspace completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to prepare workspace");
		[useExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];
	
	//delete workspace
	XCTestExpectation *delWspaceExpect = [self expectationWithDescription:@"delete workspace"];
	[server deleteWorkspce:wspace completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"Failed to delete workspace: %@", results);
		[delWspaceExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//delete our project
	XCTestExpectation *delExpect = [self expectationWithDescription:@"delete project"];
	[server deleteProject:project completionBlock:^(BOOL success, id results) {
		XCTAssertTrue(success, @"Failed to delete project: %@", results);
		[delExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

}

-(void)testFiles
{
	NSString *const wspaceName = @"ftestws";
	
	id<Rc2Server> server = RC2_SharedInstance();
	NSArray *projects = [[server activeLogin] projects];
	RCProject *project = projects.firstObject;
	XCTAssertNotNil(project, @"no default project found");
	
	__block RCWorkspace *wspace = [[project workspaces] firstObjectWithValue:wspaceName forKey:@"name"];
	if (wspace) {
		//delete existing workspace
		XCTestExpectation *delWspaceExpect = [self expectationWithDescription:@"delete workspace"];
		[server deleteWorkspce:wspace completionHandler:^(BOOL success, id results) {
			XCTAssertTrue(success, @"Failed to delete workspace: %@", results);
			[delWspaceExpect fulfill];
		}];
		[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];
	}
	//create workspace
	XCTestExpectation *createWorkExpect = [self expectationWithDescription:@"create workspace"];
	[server createWorkspace:wspaceName inProject:project completionBlock:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to create workspace: %@", results);
		wspace = results;
		XCTAssertEqualObjects(wspaceName, wspace.name, @"created workspace name incorrect");
		[createWorkExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//import files
	NSURL *file1 = [[NSBundle bundleForClass:[self class]] URLForResource:@"samples" withExtension:@"R"];
	NSURL *file2 = [[NSBundle bundleForClass:[self class]] URLForResource:@"lognormal" withExtension:@"R"];
	NSArray *files = @[file1,file2];
	XCTestExpectation *importExpect = [self expectationWithDescription:@"import files"];
	[server importFiles:files toContainer:wspace completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"failed to import files: %@", results);
		XCTAssertNotNil([wspace fileWithName:file1.lastPathComponent], @"failed to find file 1");
		XCTAssertNotNil([wspace fileWithName:file2.lastPathComponent], @"failed to find file 2");
		[importExpect fulfill];
	} progress:^(CGFloat perComplete) {
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];

	//delete file
	XCTestExpectation *fileDelExpect = [self expectationWithDescription:@"delete file 1"];
	[server deleteFile:wspace.files.firstObject container:wspace completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"Failed to delete file 1");
		XCTAssertNil([wspace fileWithName:file1.lastPathComponent], @"deleted file not removed from local workspace");
		[fileDelExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];
	
	//delete workspace
	XCTestExpectation *delWspaceExpect = [self expectationWithDescription:@"delete workspace"];
	[server deleteWorkspce:wspace completionHandler:^(BOOL success, id results) {
		XCTAssertTrue(success, @"Failed to delete workspace: %@", results);
		[delWspaceExpect fulfill];
	}];
	[self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {}];
}

@end
