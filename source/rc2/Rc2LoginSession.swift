//
//  Rc2LoginSession.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/11/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation

@objc public class Rc2LoginSession : NSObject {
	let host : String;
	let authToken : String;
	let currentUser : Rc2User;
	var workspaces : [Rc2Workspace];
	
	init(jsonData : AnyObject, host : String) {
		self.host = host
		let json = JSON(jsonData)
		authToken = json["token"].stringValue
		currentUser = Rc2User(json: json["user"])
		workspaces = Rc2Workspace.workspacesFromJsonArray(json["workspaces"])
	}
}