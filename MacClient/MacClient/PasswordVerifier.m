//
//  PasswordVerifier.m
//  MacClient
//
//  Created by Mark Lilback on 10/29/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "PasswordVerifier.h"

@interface PasswordVerifier()
@property (nonatomic, readwrite) BOOL hasWarningMessage;
@property (nonatomic, strong) NSCharacterSet *invalidCharSet;
@end

@implementation PasswordVerifier

@synthesize password1=_password1;
@synthesize password2=_password2;
@synthesize warningMessage;
@synthesize isValid;
@synthesize minLength;
@synthesize maxLength;
@synthesize validCharacterSet=_validCharacterSet;
@synthesize invalidCharSet;
@synthesize hasWarningMessage;

-(void)verifyPasswords
{
	BOOL valid=YES;
	self.warningMessage=nil;
	if (nil == self.password1 || nil == self.password2)
		valid = NO;
	else if (![self.password1 isEqualToString:self.password2]) {
		valid=NO;
		self.warningMessage = @"Passwords do not match";
	} else if (self.minLength && self.password1.length < self.minLength.integerValue) {
		valid=NO;
		self.warningMessage = [NSString stringWithFormat:@"Passwords must be at least %@ characters long", self.minLength];
	} else if (self.invalidCharSet &&
			   (NSNotFound != [self.password1 rangeOfCharacterFromSet:self.invalidCharSet].location)) 
	{
		valid=NO;
		self.warningMessage = @"Invalid characters";
	}
	self.hasWarningMessage = nil != self.warningMessage;
	self.isValid=valid;
}

-(void)setPassword1:(NSString *)password1
{
	_password1 = password1;
	[self verifyPasswords];
}

-(void)setPassword2:(NSString *)password2
{
	_password2 = password2;
	[self verifyPasswords];
}

-(void)setValidCharacterSet:(NSCharacterSet *)validCharacterSet
{
	_validCharacterSet = validCharacterSet;
	self.invalidCharSet = validCharacterSet.invertedSet;
}

@end
