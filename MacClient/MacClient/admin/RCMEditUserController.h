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
@property (nonatomic, strong) RCUser *theUser;
@property (nonatomic, strong) IBOutlet NSTextField *loginField;

-(IBAction)cancelEdit:(id)sender;
-(IBAction)saveChanges:(id)sender;
@end
