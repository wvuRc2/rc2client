//
//  Rc2Session.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation
import Starscream

protocol Rc2SessionDelegate : class {
	func sessionOpened()
	func sessionClosed()
	func sessionMessageReceived(msg:JSON)
}

@objc class Rc2Session : NSObject {
	let workspace : Rc2Workspace
	let wsSource : WebSocketSource
	weak var delegate : Rc2SessionDelegate?
	var variablesVisible : Bool = false {
		didSet {
			if variablesVisible && variablesVisible != oldValue {
				requestVariables()
			}
		}
	}
	
	private(set) var connectionOpen:Bool = false
	
	init(_ wspace:Rc2Workspace, delegate:Rc2SessionDelegate, source:WebSocketSource)
	{
		workspace = wspace
		self.delegate = delegate
		self.wsSource = source
		super.init()
	}
	
	func open() {
		self.wsSource.connect()
	}
	
	func close() {
		self.wsSource.disconnect(forceTimeout: 1)
	}
	
	//MARK: public reuest methods
	
	//MARK: private methods
	func sendMessage(message:Dictionary<String,AnyObject>) -> Bool {
		guard NSJSONSerialization.isValidJSONObject(message) else {
			return false
		}
		do {
			let json = try NSJSONSerialization.dataWithJSONObject(message, options: [])
			let jsonStr = NSString(data: json, encoding: NSUTF8StringEncoding)
			self.wsSource.writeString(jsonStr as! String)
		} catch let err as NSError {
			Rc2LogError ("error sending json message on websocket:\(err)")
			return false
		}
		return true
	}
	
	private func parseJson(text:String) -> JSON {
		let jsonData = text.dataUsingEncoding(NSUTF8StringEncoding)
		return JSON(data:jsonData!)
	}
}

//MARK: private methods
private extension Rc2Session {
	func requestVariables() {
		sendMessage(["cmd":"watchVariables", "watch":variablesVisible])
	}
}

//MARK: WebSocketDelegate implementation
extension Rc2Session : WebSocketDelegate {
	func websocketDidConnect(socket: WebSocket) {
		connectionOpen = true
		self.delegate?.sessionOpened()
	}
	func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
		connectionOpen = false
		self.delegate?.sessionClosed()
	}
	func websocketDidReceiveMessage(socket: WebSocket, text: String) {
		self.delegate?.sessionMessageReceived(JSON.parse(text))
	}
	func websocketDidReceiveData(socket: WebSocket, data: NSData) {
		
	}
}
