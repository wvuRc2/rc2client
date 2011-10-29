//
//  RCMEditUserController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMEditUserController.h"
#import "PasswordVerifier.h"
#import "RCUser.h"

@interface RCMEditUserController()
@property (nonatomic, strong) PasswordVerifier *passwordVerifier;
@end

@implementation RCMEditUserController

-(id)init
{
	return [super initWithWindowNibName:@"RCMEditUserController"];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
	self.passwordVerifier = [[PasswordVerifier alloc] init];
	self.passwordVerifier.minLength = [NSNumber numberWithInt:4];
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


-(NSString*)emailAddress
{
	return self.theUser.email;
}

-(void)setEmailAddress:(NSString *)emailAddress
{
	self.theUser.email = emailAddress;
}

-(NSString*)login
{
	return self.theUser.login;
}

-(void)setLogin:(NSString *)login
{
	self.theUser.login = login;
}

-(NSString*)name
{
	return self.theUser.name;
}

-(void)setName:(NSString *)name
{
	self.theUser.name = name;
}

@synthesize loginField;
@synthesize theUser;
@synthesize pass1Field;
@synthesize pass2Field;
@synthesize passwordVerifier;
@end
