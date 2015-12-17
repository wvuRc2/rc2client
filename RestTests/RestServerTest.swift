//
//  RestServerTest.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/16/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import XCTest
@testable import Rc2
import Mockingjay

class RestServerTest: XCTestCase {
	var server : Rc2RestServer?
	
	override func setUp() {
		super.setUp()
		NSURLSessionConfiguration.mockingjaySwizzleDefaultSessionConfiguration()
		server = Rc2RestServer()
		server?.selectHost("localhost")
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func doLogin() {
		let path : String = NSBundle(forClass: RestServerTest.self).pathForResource("loginResults", ofType: "json")!
		let resultData = NSData(contentsOfFile: path)
		stub(http(.POST, uri: "/login"), builder: jsonData(resultData!))
		let loginEx = expectationWithDescription("login")
		server?.login("test", password: "beavis", handler: { (success, results, error) -> Void in
			XCTAssert(success, "login failed:\(error)")
			loginEx.fulfill()
		})
		self.waitForExpectationsWithTimeout(2) { (err) -> Void in }
	}
	
	func testLoginData()
	{
		doLogin()
		XCTAssertNotNil(server?.loginSession)
		XCTAssertEqual("1_-6673679035999338665_-5094905675301261464", server!.loginSession!.authToken)
		XCTAssertEqual("Cornholio", server!.loginSession!.currentUser.lastName)
	}
	
	func testCreateWorkspace() {
		doLogin()
		let path : String = NSBundle(forClass: RestServerTest.self).pathForResource("createWorkspace", ofType: "json")!
		let resultData = NSData(contentsOfFile: path)
		let wspaceEx = expectationWithDescription("wspace")
		stub(http(.POST, uri:"/workspaces"), builder:jsonData(resultData!))
		var wspace : Rc2Workspace? = nil
		server?.createWorkspace("foofy", handler: { (success, results, error) -> Void in
			XCTAssertTrue(success, "failed to create workspace:\(error)")
			wspace = results as? Rc2Workspace
			wspaceEx.fulfill()
		})
		self.waitForExpectationsWithTimeout(2){ (error) in }
		XCTAssertEqual(wspace!.name, "foofy", "wrong workspace name")
	}

	func testCreateDuplicateWorkspaceFails() {
		doLogin()
		let wspaceEx = expectationWithDescription("wspace")
		stub(http(.POST, uri:"/workspaces"), builder:http(422))
		server?.createWorkspace("foofy", handler: { (success, results, error) -> Void in
			XCTAssertFalse(success, "created duplicate workspace:\(error)")
			wspaceEx.fulfill()
		})
		self.waitForExpectationsWithTimeout(2){ (error) in }
	}
}
