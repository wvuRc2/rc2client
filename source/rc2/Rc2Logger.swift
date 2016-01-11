//
//  Rc2Logger.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/16/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

public func Rc2LogError(@autoclosure logText: () -> String, level: DDLogLevel = .Error, context: Int = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = false)
{
	SwiftLogMacro(async, level: level, flag: .Error, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogWarn(@autoclosure logText: () -> String, level: DDLogLevel = .Warning, context: Int = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: .Warning, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogInfo(@autoclosure logText: () -> String, level: DDLogLevel = .Info, context: Int = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: .Info, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

public func Rc2LogVerbose(@autoclosure logText: () -> String, level: DDLogLevel = .Verbose, context: Int = 0, file: StaticString = __FILE__, function: StaticString = __FUNCTION__, line: UInt = __LINE__, tag: AnyObject? = nil, asynchronous async: Bool = true)
{
	SwiftLogMacro(async, level: level, flag: .Verbose, context: context, file: file, function: function, line: line, tag: tag, string: logText)
}

