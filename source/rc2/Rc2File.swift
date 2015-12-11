//
//  Rc2File.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/11/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation

@objc public class Rc2File : NSObject {
	let fileId : Int32
	let name : String
	let version : Int32
	let fileSize : Int32
	let dateCreated : NSDate
	let lastModified : NSDate
	
	static func filesFromJsonArray(jsonArray : AnyObject) -> [Rc2File] {
		let array = JSON(jsonArray)
		return filesFromJsonArray(array)
	}

	static func filesFromJsonArray(json : JSON) -> [Rc2File] {
		var array = [Rc2File]()
		for (_,subJson):(String, JSON) in json {
			array.append(Rc2File(json:subJson))
		}
		return array
	}

	convenience init (jsonData:AnyObject) {
		let json = JSON(jsonData)
		self.init(json: json)
	}
	
	init(json:JSON) {
		fileId = json["id"].int32Value
		name = json["name"].stringValue
		version = json["version"].int32Value
		fileSize = json["fileSize"].int32Value
		dateCreated = NSDate(timeIntervalSince1970: json["dateCreated"].doubleValue/1000.0)
		lastModified = NSDate(timeIntervalSince1970: json["lastModified"].doubleValue/1000.0)
	}
}
