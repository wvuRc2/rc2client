//
//  WebSocketSource.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/10/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation
import Starscream

//wrapper protocol around starscream's WebSocket class to allow DI and mocking
public protocol WebSocketSource : class {
	func connect()
	func disconnect(forceTimeout forceTimeout:NSTimeInterval?)
	func writeString(str:String)
	func writeData(data:NSData)
	func writePing(data:NSData)
}

//declare Starscream's WebSocket as conforming to WebSocketSource
extension WebSocket : WebSocketSource {}
