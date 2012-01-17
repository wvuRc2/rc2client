//
//  RCMAppConstants.h
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//tooolbar items
extern NSString * const RCMToolbarItem_Files;
extern NSString * const RCMToolbarItem_OpenSession;
extern NSString * const RCMToolbarItem_Back;
extern NSString * const RCMToolbarItem_Remove;
extern NSString * const RCMToolbarItem_Add;
extern NSString * const RCMToolbarItem_Users;

#define kPref_FixedFont @"FixedFont"
#define kPref_SupressDeleteFileWarning @"SupressDeleteFileWarning"
#define kPref_CommandHistoryMaxLen @"CommandHistoryMaxLen"
#define kPref_NumImagesVisible @"NumImagesVisible"

@interface RCMAppConstants : NSObject
//array of all preference keys that should be removed when users chooses to reset all warnings
+(NSArray*)alertSupressionKeys;
@end
