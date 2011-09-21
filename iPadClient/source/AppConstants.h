//
//  AppConstants.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#define kPrefLefty @"LeftyPref"
#define kPrefDynKey @"DynKeyboard"
#define kPrefCustomKey1URL @"PrefCustomKey1URL"
#define kPrefCustomKey2URL @"PrefCustomKey2URL"
#define kPrefKeyboardLayout @"KeyboardLayout"

typedef enum {
	eKeyboardLayout_Standard=0,
	eKeyboardLayout_Custom1,
	eKeyboardLayout_Custom2
} eKeyboardLayout;

#define KeyboardPrefsChangedNotification @"KeyboardPrefsChangedNotification"

#define kChatMessageNotification @"ChatMessageNotification"
