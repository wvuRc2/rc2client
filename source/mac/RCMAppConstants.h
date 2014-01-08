//
//  RCMRc2AppConstants
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Rc2AppConstants.h"

//tooolbar items
extern NSString * const RCMToolbarItem_Files;
extern NSString * const RCMToolbarItem_OpenSession;
extern NSString * const RCMToolbarItem_Back;
extern NSString * const RCMToolbarItem_Remove;
extern NSString * const RCMToolbarItem_Add;
extern NSString * const RCMToolbarItem_Users;

extern NSString *const kPref_SupressDeleteFileWarning;
extern NSString *const kPref_SupressClearWorkspaceWarning;
extern NSString *const kPref_CommandHistoryMaxLen;
extern NSString *const kPref_NumImagesVisible;
extern NSString *const kPref_EditorFont;
extern NSString *const kPref_EditorFontDisplayName;
extern NSString *const kPref_EditorFontSize;
extern NSString *const kPref_EditorWordWrap;
extern NSString *const kPref_EditorShowInvisible;
extern NSString *const kPref_TreatNewlinesAsSemicolons;
extern NSString *const kPref_ExecuteByDefault;
extern NSString *const kPref_ConsoleFontSize;

extern const NSInteger kMenuView;
extern const NSInteger kMenuView_Theme;
extern const NSInteger kMenu_Chunks;

@interface RCMAppConstants : NSObject
//array of all preference keys that should be removed when users chooses to reset all warnings
+(NSArray*)alertSupressionKeys;
@end

@interface NSPathComponentCell (RC2Helpers)
+(instancetype)pathCellWithTitle:(NSString*)title;
@end
