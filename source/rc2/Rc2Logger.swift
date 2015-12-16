//
//  Rc2Logger.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/16/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation

let Rc2LogLevel = VyanaLogger.sharedInstance().logLevelForKey("rc2")

private func SwiftLogMacro(isAsynchronous: Bool, level: Int32, flag flg: Int32, context: Int32 = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: Int32 = __LINE__, tag: AnyObject? = nil, @autoclosure string: () -> String)
{
	if level & flg != 0 {
		// Tell the DDLogMessage constructor to copy the C strings that get passed to it.
		// Using string interpolation to prevent integer overflow warning when using StaticString.stringValue
//		let logMessage = DDLogMessage(message: string(), level: level, flag: flg, context: context, file: "\(file)", function: "\(function)", line: line, tag: tag, options: [.CopyFile, .CopyFunction], timestamp: nil)
//		DDLog.log(isAsynchronous, message: logMessage)
		DDLog.log(isAsynchronous, level:level, flag:flg, context:context, file:file.stringValue, function:function.stringValue, line:line, tag:tag, format:string(), args:CVaListPointer(_fromUnsafeMutablePointer: nil))
	}
}

public func Rc2LogError(@autoclosure logText: () -> String, level: Int32 = Rc2LogLevel, context: Int32 = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: Int32 = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = false)
{
	SwiftLogMacro(async, level: level, flag: LOG_FLAG_ERROR, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogWarn(@autoclosure logText: () -> String, level: Int32 = Rc2LogLevel, context: Int32 = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: Int32 = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: LOG_FLAG_WARN, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogInfo(@autoclosure logText: () -> String, level: Int32 = Rc2LogLevel, context: Int32 = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: Int32 = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: LOG_FLAG_INFO, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogVerbose(@autoclosure logText: () -> String, level: Int32 = Rc2LogLevel, context: Int32 = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: Int32 = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: LOG_FLAG_VERBOSE, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

