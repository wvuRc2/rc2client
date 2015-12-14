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
	let files : [Rc2File]
	
	static func workspacesFromJsonArray(jsonArray : AnyObject) -> [Rc2Workspace] {
		let array = JSON(jsonArray)
		return workspacesFromJsonArray(array)
	}

	static func workspacesFromJsonArray(json : JSON) -> [Rc2Workspace] {
		var wspaces = [Rc2Workspace]()
		for (_,subJson):(String, JSON) in json {
			wspaces.append(Rc2Workspace(json:subJson))
		}
		wspaces.sortInPlace { return $0.name.localizedCompare($1.name) == .OrderedAscending }
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
		files = Rc2File.filesFromJsonArray(json["files"])
	}
	
	public override var description : String {
		return "<Rc2Workspace: \(name) (\(wspaceId))";
	}

}