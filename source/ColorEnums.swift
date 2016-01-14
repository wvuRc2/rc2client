//
//  ColorEnums.swift
//  Rc2Client
//
//  Created by Mark Lilback on 1/14/16.
//  Copyright © 2016 West Virginia University. All rights reserved.
//

import Foundation

enum OutputColors: String {
	case Input, Help, Status, Error, Note, Log
	
	static let allValues = [Input, Help, Status, Error, Note, Log]
}

enum SyntaxColors: String {
	case Comment, Keyword, Function, Quote, Symbol, CodeBackground, InlineBackground, EquationBackground
	
	static let allValues = [Comment, Keyword, Function, Quote, Symbol, CodeBackground, InlineBackground, EquationBackground]
}
