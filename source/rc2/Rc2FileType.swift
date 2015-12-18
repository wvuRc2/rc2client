//
//  Rc2FileType.swift
//  Rc2Client
//
//  Created by Mark Lilback on 12/17/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

import Foundation
#if os(OSX)
	import AppKit
#else
	import UIKit
#endif

public class Rc2FileType : NSObject {
	
	static var allFileTypes:[Rc2FileType] = {
		let fpath = NSBundle(forClass: Rc2FileType.self).pathForResource("RC2FileTypes", ofType: "plist")
		let dict = NSDictionary(contentsOfFile: fpath!)
		let rawTypes = dict!["FileTypes"] as! NSArray
		return rawTypes.map({ Rc2FileType(dictionary: $0 as! NSDictionary) })
	}()
	
	static var imageFileTypes:[Rc2FileType] = { allFileTypes.filter { return $0.isImage } }()
	static var textFileTypes:[Rc2FileType] = { allFileTypes.filter { return $0.isTextFile } }()
	static var importableFileTypes:[Rc2FileType] = { allFileTypes.filter { return $0.isImportable } }()
	static var creatableFileTypes:[Rc2FileType] = { allFileTypes.filter { return $0.isCreatable } }()
	
	var name:String { return typeDict["Name"] as! String }
	var fileExtension:String { return typeDict["Extension"] as! String }
	var details:String {return typeDict["Description"] as! String }
	var iconName:String? {return typeDict["IconName"] as? String }
	var mimeType:String {
		if let mtype = typeDict["MimeType"] as! String? {
			return mtype
		}
		return isTextFile ? "text/plain" : "application/octet-stream"
	}

	var isTextFile:Bool { return boolPropertyValue("IsTextFile") }
	var isImportable:Bool { return boolPropertyValue("Importable") }
	var isCreatable:Bool { return boolPropertyValue("Creatable") }
	var isImage:Bool { return boolPropertyValue("IsImage") }
	var isSourceFile:Bool { return boolPropertyValue("IsSrc") }
	var isSweave:Bool { return boolPropertyValue("IsSweave") }
	var isRMarkdown:Bool { return boolPropertyValue("IsRMarkdown") }
	var isExecutable:Bool { return boolPropertyValue("IsExecutable") }
	
	private let typeDict : NSDictionary
	
	class func fileTypeWithExtension(anExtension:String) -> Rc2FileType? {
		let filtered:[Rc2FileType] = Rc2FileType.allFileTypes.filter {return $0.fileExtension == anExtension }
		return filtered.first
	}
	
	private func boolPropertyValue(key:String) -> Bool {
		if let nval = typeDict[key] as! NSNumber? {
			return nval.boolValue
		}
		return false
	}
	
	init(dictionary:NSDictionary) {
		typeDict = dictionary
		super.init()
	}

	///image function differs based on platform
#if os(OSX)
	func image() -> NSImage? {
		if let img = NSImage(named: "console/\(self.fileExtension)-file") {
			return img
		}
		return NSImage(named: "console/plain-file")
	}
	func fileImage() -> NSImage? {
		if let iname = self.iconName {
			var img:NSImage?
			img = NSImage(named: iname)
			if (img == nil) {
				img = NSWorkspace.sharedWorkspace().iconForFileType(self.fileExtension)
			}
			img?.size = NSMakeSize(48, 48)
			if (img != nil) {
				return img
			}
		}
		return image()
	}
#else
	func image() -> UIImage? {
		if let img = UIImage(named: "console/\(self.fileExtension)-file") {
			return img
		}
		return UIImage(named:"console/plain-file")
	}
	func fileImage() -> UIImage? {
		return image()
	}
#endif
	
}