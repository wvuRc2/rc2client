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

#define kPref_SupressDeleteFileWarning @"SupressDeleteFileWarning"
#define kPref_SupressClearWorkspaceWarning @"SupressClearWorkspaceWarning"
#define kPref_CommandHistoryMaxLen @"CommandHistoryMaxLen"
#define kPref_NumImagesVisible @"NumImagesVisible"
#define kPref_EditorFont @"EditorFont"
#define kPref_EditorFontDisplayName @"EditorFontDisplayName"
#define kPref_EditorFontSize @"EditorFontSize"
#define kPref_EditorWordWrap @"EditorWordWrap"
#define kPref_EditorShowInvisible @"ShowInvisibleChars"
#define kPref_TreatNewlinesAsSemicolons @"TreatNewlinesAsSemicolons"
#define kPref_ExecuteByDefault @"ExecuteInsteadOfSource"

#define kMenuView 2
#define kMenuView_Theme 2112
#define kMenu_Chunks 24090

@interface RCMAppConstants : NSObject
//array of all preference keys that should be removed when users chooses to reset all warnings
+(NSArray*)alertSupressionKeys;
@end

@interface NSPathComponentCell (RC2Helpers)
+(instancetype)pathCellWithTitle:(NSString*)title;
@end