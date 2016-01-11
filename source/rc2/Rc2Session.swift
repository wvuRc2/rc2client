//
//  Rc2Session.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation
import Starscream

@objc protocol Rc2SessionDelegate : class {
	func sessionOpened()
	func sessionClosed()
}

@objc class Rc2Session : NSObject {
	let workspace : Rc2Workspace
	let wsSource : WebSocketSource
	weak var delegate : Rc2SessionDelegate?
	
	private(set) var connectionOpen:Bool = false
	
	init(_ wspace:Rc2Workspace, delegate:Rc2SessionDelegate, source:WebSocketSource)
	{
		workspace = wspace
		self.delegate = delegate
		self.wsSource = source
		super.init()
	}
	
	func open() {
		connectionOpen = true
		self.delegate?.sessionOpened()
	}
	
	func close() {
		connectionOpen = false
		self.delegate?.sessionClosed()
	}
}
