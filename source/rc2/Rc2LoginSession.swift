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
	
	init(json : JSON, host : String) {
		self.host = host
		authToken = json["token"].stringValue
		currentUser = Rc2User(json: json["user"])
		workspaces = Rc2Workspace.workspacesFromJsonArray(json["workspaces"])
	}

	public override var description : String {
		return "<RcLoginSession: \(currentUser.login)@\(host) (\(currentUser.userId))";
	}
}