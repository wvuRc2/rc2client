//
//  RCMAppConstants.m
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMAppConstants.h"

const NSInteger kMenuView = 2;
const NSInteger kMenuView_Theme = 2112;
const NSInteger kMenu_Chunks = 24090;
const NSInteger kRHelpMenuTag = 438872;

NSString * const MCEditTextDocumentNotification = @"MCEditTextDocumentNotification";

NSString *const kPref_SupressDeleteFileWarning = @"SupressDeleteFileWarning";
NSString *const kPref_SupressClearWorkspaceWarning = @"SupressClearWorkspaceWarning";
NSString *const kPref_CommandHistoryMaxLen = @"CommandHistoryMaxLen";
NSString *const kPref_NumImagesVisible = @"NumImagesVisible";
NSString *const kPref_EditorFont = @"EditorFont";
NSString *const kPref_EditorFontDisplayName = @"EditorFontDisplayName";
NSString *const kPref_EditorFontSize = @"EditorFontSize";
NSString *const kPref_EditorWordWrap = @"EditorWordWrap";
NSString *const kPref_EditorShowInvisible = @"ShowInvisibleChars";
NSString *const kPref_TreatNewlinesAsSemicolons = @"TreatNewlinesAsSemicolons";
NSString *const kPref_ExecuteByDefault = @"ExecuteInsteadOfSource";
NSString *const kPref_ConsoleFontSize = @"ConsoleFontSize";

NSString * const RCMToolbarItem_Files = @"RCMToolbarItem_Files";
NSString * const RCMToolbarItem_OpenSession = @"RCMToolbarItem_OpenSession";
NSString * const RCMToolbarItem_Back = @"RCMToolbarItem_Back";
NSString * const RCMToolbarItem_Remove = @"RCMToolbarItem_Remove";
NSString * const RCMToolbarItem_Add = @"RCMToolbarItem_Add";
NSString * const RCMToolbarItem_Users = @"RCMToolbarItem_Users";

@implementation RCMAppConstants
+(NSArray*)alertSupressionKeys
{
	static NSArray *supressKeys;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		supressKeys = @[kPref_SupressDeleteFileWarning,kPref_SupressClearWorkspaceWarning];
	});
	return supressKeys;
}
@end

@implementation NSPathComponentCell (RC2Helpers)

+(instancetype)pathCellWithTitle:(NSString*)title
{
	NSPathComponentCell *cell = [[NSPathComponentCell alloc] init];
	cell.title = title;
	return cell;
}

@end