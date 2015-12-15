//
//  Rc2RestServerTest.m
//  Rc2Client
//
//  Created by Mark Lilback on 12/11/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Rc2RestServer.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "Rc2-Swift.h"

@interface Rc2RestServerTest : XCTestCase
@property (strong) XCTestExpectation *httpExpectation;
@property (strong) Rc2RestServer *server;
@end

@implementation Rc2RestServerTest

- (void)setUp
{
	[super setUp];
	self.httpExpectation = [self expectationWithDescription:@"httpResponse"];
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	self.server = [[Rc2RestServer alloc] initWithSessionConfiguration:config];
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
	[OHHTTPStubs removeAllStubs];
}

-(void)prepareURLSessionStub:(NSString*)jsonFileName
{
	[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
		return [request.URL.host isEqualToString:@"localhost"];
	} withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
		NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:jsonFileName withExtension:@"json"];
		return [OHHTTPStubsResponse responseWithFileURL:url statusCode:200 headers:@{@"Content-Type":@"application/json"}];
	}];
}

-(void)waitForHttpExpectation
{
	[self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
		NSLog(@"error waiting for expectation:%@", error);
	}];
}

-(void)testLoginData
{
	[self prepareURLSessionStub:@"loginResults"];
	[self.server loginToHostName:@"localhost" login:@"test" password:@"beavis" handler:^(BOOL success, id results, NSError *error)
	 {
		XCTAssertTrue(success, @"login failed: %@", error);
		[self.httpExpectation fulfill];
	 }];
	[self waitForHttpExpectation];
	
	XCTAssertNotNil(self.server.loginSession, @"no login session found");
	XCTAssertEqualObjects(@"1_-6673679035999338665_-5094905675301261464", [self.server valueForKeyPath:@"loginSession.authToken"], @"tokens not equal");
	XCTAssertEqualObjects(@"Cornholio", [self.server valueForKeyPath:@"loginSession.currentUser.lastName"], @"names not equal");
}

-(void)testCreateDeleteWorkspace
{
	
}

/*
- (void)testLogin {
	// This is an example of a functional test case.
	// Use XCTAssert and related functions to verify your tests produce the correct results.
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//	XCTestExpectation *loginExpectation = [self expectationWithDescription:@"login"];
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	Rc2RestServer *server = [[Rc2RestServer alloc] initWithSessionConfiguration:config];
	[server loginToHostName:@"localhost" login:@"test" password:@"beavis" handler:^(BOOL success, id results, NSError *error)
	{
		XCTAssertTrue(success, @"login failed: %@", error);
		dispatch_semaphore_signal(semaphore);
//		[loginExpectation fulfill];
	}];
	long rc = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC));
	XCTAssertEqual(rc, 0, @"login failed");
//	[self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {}];
}
*/

@end
