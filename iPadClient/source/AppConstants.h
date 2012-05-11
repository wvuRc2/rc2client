//
//  AppConstants.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#define kPrefLastLogin @"LastLogin"
#define kPrefLefty @"LeftyPref"
#define kPrefDynKey @"DynKeyboard"
#define kPrefCustomKey1URL @"PrefCustomKey1URL"
#define kPrefCustomKey2URL @"PrefCustomKey2URL"
#define kPrefKeyboardLayout @"KeyboardLayout"
#define kPref_SyntaxColor_Comment @"SyntaxColor_Comment"
#define kPref_SyntaxColor_Function @"SyntaxColor_Function"
#define kPref_SyntaxColor_Keyword @"SyntaxColor_Keyword"

typedef enum {
	eKeyboardLayout_Standard=0,
	eKeyboardLayout_Custom1,
	eKeyboardLayout_Custom2
} eKeyboardLayout;

#define KeyboardPrefsChangedNotification @"KeyboardPrefsChangedNotification"

#define kChatMessageNotification @"ChatMessageNotification"

#define kTableViewDoubleClickedNotification @"kTableViewDoubleClickedNotification"
