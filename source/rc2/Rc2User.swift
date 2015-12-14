//
//  Rc2User.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation

@objc public class Rc2User : NSObject {
	let userId : Int32;
	let login : String;
	let version : Int32;
	let firstName: String;
	let lastName: String;
	let email: String;
	let admin: Bool;
	
	convenience init (jsonData:AnyObject) {
		let json = JSON(jsonData)
		self.init(json: json)
	}
	
	init(json : JSON) {
		userId = json["id"].int32Value
		login = json["login"].stringValue
		version = json["version"].int32Value
		firstName = json["firstName"].stringValue
		lastName = json["lastName"].stringValue
		email = json["email"].stringValue
		admin = json["admin"].boolValue
	}
	
	public override var description : String {
		return "<Rc2User: \(login) (\(userId))";
	}
}