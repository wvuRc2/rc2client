//
//  RCMEditUserController.h
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCUser;

@interface RCMEditUserController : NSWindowController
//only property caller needs to worry about. rest are IB-related
@property (nonatomic, strong) RCUser *theUser;

@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *login;
@property (nonatomic, assign) BOOL isValid;

@property (nonatomic, strong) IBOutlet NSTextField *loginField;
@property (nonatomic, strong) IBOutlet NSSecureTextField *pass1Field;
@property (nonatomic, strong) IBOutlet NSSecureTextField *pass2Field;

-(IBAction)cancelEdit:(id)sender;
-(IBAction)saveChanges:(id)sender;
@end
