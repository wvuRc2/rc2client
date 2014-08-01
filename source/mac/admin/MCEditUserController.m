//
//  MCEditUserController.m
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCEditUserController.h"
#import "PasswordVerifier.h"
#import "RCUser.h"
#import "Rc2Server.h"
#import "RCActiveLogin.h"

@interface MCEditUserController()
@property (nonatomic, strong) PasswordVerifier *passwordVerifier;
@property (strong) NSArray *ldapServers;
@property (nonatomic, strong) NSDictionary *selectedLdapServer;

@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *ldapLogin;
@property (nonatomic, strong) NSNumber *ldapServerId;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, assign) BOOL useLdap;

@property (nonatomic, strong) IBOutlet NSTextField *loginField;
@property (nonatomic, strong) IBOutlet NSSecureTextField *pass1Field;
@property (nonatomic, strong) IBOutlet NSSecureTextField *pass2Field;

-(void)checkValidity;
@end

@implementation MCEditUserController

-(id)init
{
	return [super initWithWindowNibName:@"MCEditUserController"];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
	self.ldapServers = [Rc2Server sharedInstance].activeLogin.ldapServers;
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
	else if (self.useLdap && self.ldapServerId != nil && self.ldapLogin.length < 2)
		v = NO;
	if (self.theUser.existsOnServer) {
		if (self.passwordVerifier.password1.length > 0 || self.passwordVerifier.password2.length > 0)
			v = self.passwordVerifier.isValid;
	} else if (!self.passwordVerifier.isValid) {
		v = NO;
	}
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
	return self.theUser.firstname;
}

-(void)setName:(NSString *)name
{
	self.theUser.firstname = name;
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

-(NSString*)selectedPassword
{
	return self.pass1Field.stringValue;
}

@end
