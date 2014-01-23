//
//  MCEditUserController.h
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCUser;

@interface MCEditUserController : NSWindowController
//only property caller needs to worry about. rest are IB-related
@property (nonatomic, strong) RCUser *theUser;
@property (nonatomic, readonly) NSString *selectedPassword;

-(IBAction)cancelEdit:(id)sender;
-(IBAction)saveChanges:(id)sender;
@end
