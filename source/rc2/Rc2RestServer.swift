//
//  Rc2RestServer.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/15/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation


@objc public class Rc2RestServer : NSObject {

	private static var sInstance = Rc2RestServer()
	private let kServerHostKey = "ServerHostKey"
	
	///singleton accessor
	public static var sharedInstance : Rc2RestServer {
		get {
			return sInstance
		}
	}
	
	public typealias Rc2RestCompletionHandler = (success:Bool, results:AnyObject?, error:NSError?) -> Void
	
	private var urlConfig : NSURLSessionConfiguration
	private var urlSession : NSURLSession
	private(set) public var hosts : [NSDictionary]
	private(set) public var selectedHost : NSDictionary
	private(set) public var loginSession : Rc2LoginSession?
	private var baseUrl : NSURL

	var restHosts : [String] {
		get {
			return hosts.map({ $0["name"]! as! String })
		}
	}
	var connectionDescription : String {
		get {
			let login = loginSession?.currentUser.login
			let host = loginSession?.host
			if (host == "rc2") {
				return login!;
			}
			return "\(login)@\(host)"
		}
	}
	
	//private init so instance is unique
	override init() {
		var userAgent = "Rc2 iOSClient"
		#if os(OSX)
			userAgent = "Rc2 MacClient"
		#endif
		urlConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		urlConfig.HTTPAdditionalHeaders = ["User-Agent": userAgent, "Accept": "application/json"]
		urlSession = NSURLSession.init(configuration: urlConfig)
		
		//load hosts info from resource file
		let hostFileUrl = NSBundle.mainBundle().URLForResource("Rc2RestHosts", withExtension: "json")
		assert(hostFileUrl != nil, "failed to get Rc2RestHosts.json URL")
		let jsonData = NSData(contentsOfURL: hostFileUrl!)
		let json = JSON(data:jsonData!)
		let theHosts = json["hosts"].arrayObject!
		assert(theHosts.count > 0, "invalid hosts data")
		hosts = theHosts as! [NSDictionary]
		selectedHost = hosts.first!
		self.baseUrl = NSURL() //dummy place holder
		super.init()
		if let previousHostName = NSUserDefaults.standardUserDefaults().stringForKey(self.kServerHostKey) {
			selectHost(previousHostName)
		}
	}
	
	private func createError(code:Int, description:String) -> NSError {
		return NSError(domain: Rc2ErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString(description, comment: "")])
	}
	
	private func request(path:String, method:String, jsonDict:NSDictionary) -> NSMutableURLRequest {
		let url = NSURL(string: path, relativeToURL: baseUrl)
		let request = NSMutableURLRequest(URL: url!)
		request.HTTPMethod = method
		if loginSession != nil {
			request.addValue(loginSession!.authToken, forHTTPHeaderField:"Rc-2Auth")
		}
		if (jsonDict.count > 0) {
			request.addValue("application/json", forHTTPHeaderField:"Content-Type")
			request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonDict, options: [])
		}
		return request
	}
	
	public func selectHost(hostName:String) {
		if let hostDict = hosts.filter({ return ($0["name"] as! String) == hostName }).first {
			selectedHost = hostDict
			let hprotocol = hostDict["secure"]!.boolValue! ? "https" : "http"
			let hoststr = "\(hprotocol)://\(hostDict["host"]!.stringValue):\(hostDict["port"]!.stringValue)/"
			baseUrl = NSURL(string: hoststr)!
		}
	}
	
	public func login(login:String, password:String, handler:Rc2RestCompletionHandler) {
		let req = request("login", method:"POST", jsonDict: ["login":login, "password":password])
		let task = urlSession.dataTaskWithRequest(req) {
			(data, response, error) -> Void in
			let json = JSON(data:data!)
			let httpResponse = response as! NSHTTPURLResponse
			switch(httpResponse.statusCode) {
				case 200:
					self.loginSession = Rc2LoginSession(json: json, host: self.selectedHost["name"]! as! String)
					dispatch_async(dispatch_get_main_queue(), { handler(success: true, results: self.loginSession!, error: nil) })
					NSUserDefaults.standardUserDefaults().setObject(self.loginSession!.host, forKey: self.kServerHostKey)
					NSNotificationCenter.defaultCenter().postNotificationName(Rc2RestLoginChangedNotification, object: self)
				case 401:
					let error = self.createError(401, description: "Invalid login or password")
					Rc2LogVerbose("\(__FUNCTION__) got a \(httpResponse.statusCode)")
					dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
				default:
					let error = self.createError(httpResponse.statusCode, description: "")
					Rc2LogWarn("\(__FUNCTION__) got unknown error: \(httpResponse.statusCode)")
					dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
			}
		}
		task.resume()
	}
	
	public func createWorkspace(wspaceName:String, handler:Rc2RestCompletionHandler) {
		let req = request("workspaces", method:"POST", jsonDict: ["name":wspaceName])
		let task = urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
			let json = JSON(data:data!)
			let httpResponse = response as! NSHTTPURLResponse
			switch(httpResponse.statusCode) {
			case 200:
				let wspace = Rc2Workspace(json: json)
				var spaces = (self.loginSession?.workspaces)!
				spaces.append(wspace)
				self.loginSession?.workspaces = spaces
				dispatch_async(dispatch_get_main_queue(), { handler(success: true, results: wspace, error: nil) })
			case 422:
				let error = self.createError(422, description: "A workspace with that name already exists")
				Rc2LogVerbose("\(__FUNCTION__) got duplicate error")
				dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
			default:
				let error = self.createError(httpResponse.statusCode, description: "")
				Rc2LogWarn("\(__FUNCTION__) got unknown error: \(httpResponse.statusCode)")
				dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
			}
		}
		task.resume()
	}

	public func renameWorkspace(wspace:Rc2Workspace, newName:String, handler:Rc2RestCompletionHandler) {
		let req = request("workspaces/\(wspace.wspaceId)", method:"PUT", jsonDict: ["name":newName, "id":Int(wspace.wspaceId)])
		let task = urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
			let json = JSON(data!)
			let httpResponse = response as! NSHTTPURLResponse
			switch(httpResponse.statusCode) {
			case 200:
				let modWspace = Rc2Workspace(json: json)
				var spaces = (self.loginSession?.workspaces)!
				spaces[spaces.indexOf(wspace)!] = modWspace
				dispatch_async(dispatch_get_main_queue(), { handler(success: true, results: modWspace, error: nil) })
			default:
				let error = self.createError(httpResponse.statusCode, description: "")
				Rc2LogWarn("\(__FUNCTION__) got unknown error: \(httpResponse.statusCode)")
				dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
			}
		}
		task.resume()
	}

	
	public func deleteWorkspace(wspace:Rc2Workspace, handler:Rc2RestCompletionHandler) {
		let req = request("workspaces/\(wspace.wspaceId)", method:"DELETE", jsonDict: [:])
		let task = urlSession.dataTaskWithRequest(req) { (data, response, error) -> Void in
			let httpResponse = response as! NSHTTPURLResponse
			switch(httpResponse.statusCode) {
			case 204:
				self.loginSession?.workspaces.removeAtIndex((self.loginSession?.workspaces.indexOf(wspace))!)
				dispatch_async(dispatch_get_main_queue(), { handler(success: true, results: nil, error: nil) })
			default:
				let error = self.createError(httpResponse.statusCode, description: "")
				Rc2LogWarn("\(__FUNCTION__) got unknown error: \(httpResponse.statusCode)")
				dispatch_async(dispatch_get_main_queue(), { handler(success: false, results: nil, error: error) })
			}
		}
		task.resume()
	}

}

