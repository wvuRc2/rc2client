//
//  RCMAppConstants.m
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMAppConstants.h"

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
	cell.title = [NSString stringWithFormat:@" %@ ", title];
	return cell;
}

@end