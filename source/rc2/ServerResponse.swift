//
//  ServerResponse.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/13/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation

public enum ServerResponse {
	case Error(queryId:Int, error:String)
	case EchoQuery(queryId:Int, fileId:Int, query:String)
	case ExecComplete(queryId:Int, batchId:Int, images:[SessionImage])
	case Help(topic:String, paths:[String])
	case Results(queryId:Int, fileId:Int, text:String)
	case Variable(socketId:Int, delta:Bool, single:Bool, variables:Dictionary<String, JSON>)
	
	static func parseResponse(jsonObj:JSON) -> ServerResponse? {
		switch(jsonObj["msg"].stringValue) {
			case "results":
				if jsonObj["images"] != nil {
					let images = jsonObj["images"].arrayValue.map({ return SessionImage($0) })
					return ServerResponse.ExecComplete(queryId: jsonObj["queryId"].intValue, batchId: jsonObj["imageBatchId"].intValue, images: images)
			} else {
					return ServerResponse.Results(queryId: jsonObj["queryId"].intValue, fileId: jsonObj["fileId"].intValue, text: jsonObj["string"].stringValue)
			}
			case "error":
				return ServerResponse.Error(queryId: jsonObj["queryId"].intValue, error: jsonObj["error"].stringValue)
			case "echo":
				return ServerResponse.EchoQuery(queryId: jsonObj["queryId"].intValue, fileId: jsonObj["fileId"].intValue, query: jsonObj["query"].stringValue)
			case "help":
				return ServerResponse.Help(topic: jsonObj["topic"].stringValue, paths: jsonObj["paths"].arrayValue.map({ return $0.stringValue }))
			case "variables":
				return ServerResponse.Variable(socketId: jsonObj["socketId"].intValue, delta: jsonObj["delta"].boolValue, single: jsonObj["singleValue"].boolValue, variables: jsonObj["variables"].dictionaryValue)
			default:
				return nil
		}
	}
}

public func == (a:ServerResponse, b:ServerResponse) -> Bool {
	switch (a, b) {
		case (.Error(let q1, let e1), .Error(let q2, let e2)):
			return q1 == q2 && e1 == e2
		case (.EchoQuery(let q1, let f1, let s1), .EchoQuery(let q2, let f2, let s2)):
			return q1 == q2 && f1 == f2 && s1 == s2
		case (.ExecComplete(let q1, let b1, let i1), .ExecComplete(let q2, let b2, let i2)):
			return q1 == q2 && b1 == b2 && i1 == i2
		case (.Help(let t1, let p1), .Help(let t2, let p2)):
			return t1 == t2 && p1 == p2
		case (.Results(let q1, let f1, let t1), .Results(let q2, let f2, let t2)):
			return q1 == q2 && f1 == f2 && t1 == t2
		case (.Variable(let s1, let d1, let sn1, let v1), .Variable(let s2, let d2, let sn2, let v2)):
			return s1 == s2 && d1 == d2 && sn1 == sn2 && v1 == v2
		default:
			return false
	}
}


public struct SessionImage: Equatable {
	let id:Int
	let batchId:Int
	let name:String
	let dateCreated:NSDate
	let imageData:NSData
	
	private static var dateFormatter:NSDateFormatter = {
		let formatter = NSDateFormatter()
		formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		formatter.dateFormat = "YYYY-MM-dd"
		return formatter
	}()
	
	init(_ jsonObj:JSON) {
		self.id = jsonObj["id"].intValue
		self.batchId = jsonObj["batchId"].intValue
		self.name = jsonObj["name"].stringValue
		self.dateCreated = SessionImage.dateFormatter.dateFromString(jsonObj["dateCreated"].stringValue)!
		self.imageData = NSData(base64EncodedString: jsonObj["imageData"].stringValue, options: [])!
	}
}

public func ==(a:SessionImage, b:SessionImage) -> Bool {
	return a.id == b.id
}

