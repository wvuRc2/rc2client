//
//  RCMEditUserController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMEditUserController.h"

@implementation RCMEditUserController

-(id)init
{
	return [super initWithWindowNibName:@"RCMEditUserController"];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
	AMCharacterSetFormatter *fmt = [[AMCharacterSetFormatter alloc] init];
	fmt.characterSet = [NSCharacterSet alphanumericCharacterSet];
	self.loginField.formatter = fmt;
}

-(IBAction)cancelEdit:(id)sender
{
	[NSApp endSheet:self.window returnCode:NSCancelButton];
}

-(IBAction)saveChanges:(id)sender
{
	[NSApp endSheet:self.window returnCode:NSOKButton];
}


@synthesize loginField;
@synthesize theUser;
@end
