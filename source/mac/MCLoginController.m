//
//  MCLoginController.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCLoginController.h"
#import "Rc2Server.h"
#import "Rc2AppConstants.h"
#import "SSKeychain.h"


@interface MCLoginController()
@property (nonatomic, copy) BasicBlock_t completionHandler;
-(void)saveLoginInfo;
-(void)loadPasswordForLogin;
-(NSString*)selectedHost;
@end

@implementation MCLoginController

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MCLoginController"])) {
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	NSString *lastLogin = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastLogin];
	if (lastLogin) {
		self.loginName = lastLogin;
		[self loadPasswordForLogin];
	}
	self.selectedServerIdx = [RC2_SharedInstance() serverHost];
}

-(void)promptForLoginWithCompletionBlock:(void (^)(void))cblock
{
	self.completionHandler = cblock;
	[self.window makeKeyAndOrderFront:self];
	[self.window center];
}

-(IBAction)doLogin:(id)sender
{
	self.isBusy=YES;
	RC2_SharedInstance().serverHost = self.selectedServerIdx;
	__block MCLoginController *blockSelf = self;
	[RC2_SharedInstance() loginAsUser:self.loginName password:self.password
		completionHandler:^(BOOL success, NSString *message) 
		{
			blockSelf.isBusy=NO;
			if (success) {
				if (RC2_SharedInstance().loggedIn) {
					[blockSelf.window orderOut:self];
					blockSelf.completionHandler();
				}
				[blockSelf saveLoginInfo];
			} else {
				[NSAlert displayAlertWithTitle:@"Error" details:message window:blockSelf.window];
			}
		}];
}

-(void)saveLoginInfo
{
	[SSKeychain setPassword:self.password forService:@"rc2" account:self.loginName];
	[[NSUserDefaults standardUserDefaults] setObject:self.loginName forKey:kPrefLastLogin];
}

-(void)loadPasswordForLogin
{
	NSString *pass = [SSKeychain passwordForService:@"rc2" account:self.loginName];
	if (pass)
		self.password = pass;
}

-(NSString*)selectedHost
{
	switch(self.selectedServerIdx) {
		case 0:
		default:
			return @"rc2.stat.wvu.edu";
		case 1:
			return @"barney.stat.wvu.edu";
		case 2:
			return @"localhost";
	}
}
						  
@end
