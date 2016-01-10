//
//  Rc2SessionTests.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import XCTest
@testable import Rc2

class Rc2SessionTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testSessionCreation() {
		let wspaceJson = "[{\"id\":1, \"userId\":1, \"version\":1, \"name\":\"foofy\", \"files\":[]}]"
		let jsonData = wspaceJson.dataUsingEncoding(NSUTF8StringEncoding)
		let sjson = JSON(data: jsonData!)
		let wspace = Rc2Workspace(json:sjson)
		let delegate = SessionDelegate()
		let session = Rc2Session(wspace, delegate:delegate)
		XCTAssertNotNil(session)
		XCTAssertEqual(wspace, session.workspace)
		XCTAssert(delegate === session.delegate)
		
		XCTAssertFalse(session.connectionOpen)
		let openEx = expectationWithDescription("open session")
		delegate.expectation = openEx
		session.open()
		waitForExpectationsWithTimeout(3) { (error) -> Void in
		}
		XCTAssertTrue(session.connectionOpen)
		delegate.expectation = expectationWithDescription("close session")
		session.close()
		waitForExpectationsWithTimeout(3) { (error) -> Void in
		}
		XCTAssertFalse(session.connectionOpen)
	}

	@objc class SessionDelegate: NSObject, Rc2SessionDelegate {
		var expectation: XCTestExpectation?
		func sessionOpened() {
			expectation?.fulfill()
		}
		func sessionClosed() {
			expectation?.fulfill()
		}
	}
}
