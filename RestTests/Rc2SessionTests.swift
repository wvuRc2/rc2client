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

	func testSendMessage() {
		let dict = ["foo":"bar", "age":21]
		session!.sendMessage(dict)
		let jsonData = wsSrc.lastStringWritten?.dataUsingEncoding(NSUTF8StringEncoding)
		let jsonObj = JSON(data:jsonData!)
		XCTAssertEqual(dict["foo"], jsonObj["foo"].stringValue)
		XCTAssertEqual(21, jsonObj["age"].int32Value)
	}
	
	func testSendMessageFailure() {
		let dict = ["foo":wspace!, "bar":22]
		let success = session!.sendMessage(dict)
		XCTAssertFalse(success)
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
		var lastStringWritten:String?
		
		func connect() {
		}
		func disconnect(forceTimeout forceTimeout: NSTimeInterval?) {
		}
		func writeString(str: String) {
			lastStringWritten = str
		}
		func writeData(data: NSData) {
		}
		func writePing(data: NSData) {
		}
	}
}
