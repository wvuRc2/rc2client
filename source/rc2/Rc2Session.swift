//
//  Rc2Session.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation
import Starscream
#if os(OSX)
	import AppKit
#endif

protocol Rc2SessionDelegate : class {
	func sessionOpened()
	func sessionClosed()
	func sessionMessageReceived(msg:JSON)
	func loadHelpItems(topic:String, items:[HelpItem])
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
	var helpRegex : NSRegularExpression = {
		return try! NSRegularExpression(pattern: "(help\\(\\\"?([\\w\\d]+)\\\"?\\))\\s*;?\\s?", options: [.DotMatchesLineSeparators])
	}()
	
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
	func executeScript(var script: String) {
		//don't send empty scripts
		guard script.characters.count > 0 else {
			return
		}
		let helpCheck = helpRegex.firstMatchInString(script, options: [], range: NSMakeRange(0, script.utf16.count))
		if helpCheck?.numberOfRanges == 3 {
			let topic = script.substringWithRange((helpCheck?.rangeAtIndex(2).toStringRange(script))!)
			let adjScript = script.stringByReplacingCharactersInRange((helpCheck?.range.toStringRange(script))!, withString: "")
			lookupInHelp(topic)
			guard adjScript.utf16.count > 0 else {
				return
			}
			script = adjScript
		}
		sendMessage(["msg":"execute", "code":script])
	}
	
	func executeScriptFile(fileId:Int) {
		sendMessage(["msg":"execute", "fileId":fileId])
	}
	
	func clearVariables() {
		executeScript("rc2.clearEnvironment()");
	}
	
	func lookupInHelp(str:String) {
		sendMessage(["msg":"help", "topic":str])
	}
	
	func requestUserList() {
		sendMessage(["msg":"userList"])
	}
	
	func forceVariableRefresh() {
		sendMessage(["msg":"watchVariables", "watch":true])
	}
	
	//MARK: other public methods
	func outputColorForKey(key:OutputColors) -> Color {
		let dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("OutputColors") as! Dictionary<String,String>
		return try! Color(hex: dict[key.rawValue]!)
	}
	
	func noHelpFoundString(topic:String) -> NSAttributedString {
		return NSAttributedString(string: "No help available for '\(topic)'\n", attributes: [NSForegroundColorAttributeName:outputColorForKey(.Help)])
	}
	
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
}

//MARK: private methods
private extension Rc2Session {
	func requestVariables() {
		sendMessage(["cmd":"watchVariables", "watch":variablesVisible])
	}
	
	func handleHelpResults(rsp:ServerResponse) {
		guard case let .Help(topic, items) = rsp else {
			assertionFailure("argument was not a help response")
			return
		}
		self.delegate?.loadHelpItems(topic, items: items)
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
