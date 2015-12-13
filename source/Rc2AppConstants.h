//
//  Rc2AppConstants.h
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

extern NSString *const RC2IdleTimerFiredNotification;
extern NSString *const Rc2ErrorDomain;

extern NSString *const kPrefLastLogin;

//iOS ones, many which need to be removed/deprecated
extern NSString *const kPrefCustomKey1URL;
extern NSString *const kPrefCustomKey2URL;
extern NSString *const kPrefKeyboardLayout;
extern NSString *const kPref_CurrentSessionWorkspace;
extern NSString *const kPref_CurrentProject;

//syntax coloring
extern NSString *const kPref_SyntaxColor_Comment;
extern NSString *const kPref_SyntaxColor_Function;
extern NSString *const kPref_SyntaxColor_Keyword;
extern NSString *const kPref_SyntaxColor_Quote;
extern NSString *const kPref_SyntaxColor_Symbol;
extern NSString *const kPref_SyntaxColor_CodeBackground;
extern NSString *const kPref_SyntaxColor_EquationBackground;
extern NSString *const kPref_SyntaxColor_InlineBackground;

//editor
extern NSString *const kPref_EditorFontColor;
extern NSString *const kPref_EditorBGColor;
extern NSString *const kPref_SearchResultBGColor;

//notifications
extern NSString *const kDropboxSyncRequestedNotification;
extern NSString *const kWillDisplayGearMenu;

//helper function
static inline void dispatchOnMainQueue(dispatch_block_t block) {
	dispatch_async(dispatch_get_main_queue(), block);
}
