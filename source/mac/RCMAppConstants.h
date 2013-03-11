//
//  RCMAppConstants.h
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//tooolbar items
extern NSString * const RCMToolbarItem_Files;
extern NSString * const RCMToolbarItem_OpenSession;
extern NSString * const RCMToolbarItem_Back;
extern NSString * const RCMToolbarItem_Remove;
extern NSString * const RCMToolbarItem_Add;
extern NSString * const RCMToolbarItem_Users;

#define kPref_SupressDeleteFileWarning @"SupressDeleteFileWarning"
#define kPref_CommandHistoryMaxLen @"CommandHistoryMaxLen"
#define kPref_NumImagesVisible @"NumImagesVisible"
#define kPref_SyntaxColor_Comment @"SyntaxColor_Comment"
#define kPref_SyntaxColor_Function @"SyntaxColor_Function"
#define kPref_SyntaxColor_Keyword @"SyntaxColor_Keyword"
#define kPref_EditorFont @"EditorFont"
#define kPref_EditorFontDisplayName @"EditorFontDisplayName"
#define kPref_EditorFontSize @"EditorFontSize"
#define kPref_EditorFontColor @"EditorFontColor"
#define kPref_EditorBGColor @"EditorBGColor"
#define kPref_EditorWordWrap @"EditorWordWrap"

#define kMenuView 2
#define kMenuView_Theme 2112

@interface RCMAppConstants : NSObject
//array of all preference keys that should be removed when users chooses to reset all warnings
+(NSArray*)alertSupressionKeys;
@end
