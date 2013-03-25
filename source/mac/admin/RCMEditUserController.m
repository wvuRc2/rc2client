//
//  RCMEditUserController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMEditUserController.h"
#import "PasswordVerifier.h"
#import "RCUser.h"
#import "Rc2Server.h"

@interface RCMEditUserController()
@property (nonatomic, strong) PasswordVerifier *passwordVerifier;
@property (strong) NSArray *ldapServers;
@property (nonatomic, strong) NSDictionary *selectedLdapServer;
@property (nonatomic, assign) BOOL useLdap;
-(void)checkValidity;
@end

@implementation RCMEditUserController

-(id)init
{
	return [super initWithWindowNibName:@"RCMEditUserController"];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
	self.ldapServers = [[Rc2Server sharedInstance] ldapServers];
	self.selectedLdapServer = [self.ldapServers firstObject];
	self.passwordVerifier = [[PasswordVerifier alloc] init];
	self.passwordVerifier.minLength = [NSNumber numberWithInt:4];
//	AMCharacterSetFormatter *fmt = [[AMCharacterSetFormatter alloc] init];
//	fmt.characterSet = [NSCharacterSet alphanumericCharacterSet];
//	self.loginField.formatter = fmt;
}

-(IBAction)cancelEdit:(id)sender
{
	[NSApp endSheet:self.window returnCode:NSCancelButton];
}

-(IBAction)saveChanges:(id)sender
{
	[NSApp endSheet:self.window returnCode:NSOKButton];
}

-(void)checkValidity
{
	BOOL v=YES;
	if (self.theUser.email.length < 4)
		v = NO;
	else if (self.login.length < 2)
		v = NO;
	else if (self.name.length < 2)
		v = NO;
	else if (self.ldapServerId != nil && self.ldapLogin.length < 2)
		v = NO;
	self.isValid = v;
}

-(void)setTheUser:(RCUser *)theUser
{
	_theUser = theUser;
	[self willChangeValueForKey:@"login"];
	[self didChangeValueForKey:@"login"];
	[self willChangeValueForKey:@"emailAddress"];
	[self didChangeValueForKey:@"emailAddress"];
	[self willChangeValueForKey:@"name"];
	[self didChangeValueForKey:@"name"];
	[self willChangeValueForKey:@"selectedLdapServer"];
	[self didChangeValueForKey:@"selectedLdapServer"];
	[self willChangeValueForKey:@"ldapLogin"];
	[self didChangeValueForKey:@"ldapLogin"];
	self.passwordVerifier.password1 = @"";
	self.passwordVerifier.password2 = @"";
}

-(NSString*)emailAddress
{
	return self.theUser.email;
}

-(void)setEmailAddress:(NSString *)emailAddress
{
	self.theUser.email = emailAddress;
	[self checkValidity];
}

-(NSString*)login
{
	return self.theUser.login;
}

-(void)setLogin:(NSString *)login
{
	self.theUser.login = login;
	[self checkValidity];
}

-(NSString*)name
{
	return self.theUser.name;
}

-(void)setName:(NSString *)name
{
	self.theUser.name = name;
	[self checkValidity];
}

-(void)setUseLdap:(BOOL)useLdap
{
	_useLdap = useLdap;
	self.passwordVerifier.enabled = !useLdap;
}

-(NSString*)ldapLogin
{
	return self.theUser.ldapLogin;
}

-(void)setLdapLogin:(NSString *)ldapLogin
{
	self.theUser.ldapLogin = ldapLogin;
	[self checkValidity];
}

-(void)setSelectedLdapServer:(NSDictionary *)selectedLdapServer
{
	_selectedLdapServer = selectedLdapServer;
	self.ldapServerId = [selectedLdapServer objectForKey:@"id"];
	if (self.useLdap)
		self.theUser.ldapServerId = self.ldapServerId;
}

@end
