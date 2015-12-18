//
//  Rc2FileTypeTest.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/18/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import XCTest
@testable import Rc2;

class Rc2FileTypeTest: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testFileTypes() {
		XCTAssert(Rc2FileType.allFileTypes.count > 12, "too few file types")
		let  sweave = Rc2FileType.fileTypeWithExtension("Rnw")!
		XCTAssertTrue(sweave.isSweave)
		XCTAssertFalse(sweave.isImage)
		let  png = Rc2FileType.fileTypeWithExtension("png")!
		XCTAssertTrue(png.isImage)
		XCTAssertFalse(png.isSourceFile)
		XCTAssertEqual(png.mimeType, "image/png")
		XCTAssertEqual(Rc2FileType.imageFileTypes.count, 3)
		XCTAssertTrue(Rc2FileType.imageFileTypes.contains(png))
	}
}
