//
//  Rc2Workspace.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation

@objc public class Rc2Workspace : NSObject {
	let wspaceId : Int32
	let userId : Int32
	let name : String
	let version : Int32
	
	static func workspacesFromJsonArray(jsonArray : AnyObject) -> [Rc2Workspace] {
		let array = JSON(jsonArray)
		var wspaces = [Rc2Workspace]()
		for (_,subJson):(String, JSON) in array {
			wspaces.append(Rc2Workspace(json:subJson))
		}
		return wspaces
	}
	
	convenience init (jsonData:AnyObject) {
		let json = JSON(jsonData)
		self.init(json: json)
	}
	
	init(json:JSON) {
		wspaceId = json["id"].int32Value
		userId = json["userId"].int32Value
		version = json["version"].int32Value
		name = json["name"].stringValue
	}
}