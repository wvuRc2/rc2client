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
	static let wspaceJson = "[{\"id\":1, \"userId\":1, \"version\":1, \"name\":\"foofy\", \"files\":[]}]"
	static let jsonData = wspaceJson.dataUsingEncoding(NSUTF8StringEncoding)
	static let sjson = JSON(data: jsonData!)
	var wspace:Rc2Workspace?
	let delegate = SessionDelegate()
	let wsSrc = MockWebSocket()
	var session: Rc2Session?

	override func setUp() {
		super.setUp()
		wspace = Rc2Workspace(json:Rc2SessionTests.sjson)
		session = Rc2Session(wspace!, delegate:delegate, source:wsSrc)
	}
	
	override func tearDown() {
		super.tearDown()
	}

	func testSessionCreation() {
		XCTAssertNotNil(session)
		XCTAssertEqual(wspace, session!.workspace)
		XCTAssert(delegate === session!.delegate)
	}
	
	func testOpenCloseSession() {
		XCTAssertFalse(session!.connectionOpen)
		let openEx = expectationWithDescription("open session")
		delegate.expectation = openEx
		session!.open()
		waitForExpectationsWithTimeout(3) { (error) -> Void in
		}
		XCTAssertTrue(session!.connectionOpen)
		delegate.expectation = expectationWithDescription("close session")
		session!.close()
		waitForExpectationsWithTimeout(3) { (error) -> Void in
		}
		XCTAssertFalse(session!.connectionOpen)
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
	
	class MockWebSocket: WebSocketSource {
		func connect() {
		}
		func disconnect(forceTimeout forceTimeout: NSTimeInterval?) {
		}
		func writeString(str: String) {
		}
		func writeData(data: NSData) {
		}
		func writePing(data: NSData) {
		}
	}
}
