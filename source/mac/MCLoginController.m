//
//  MCLoginController.m
//  Rc2Client
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "Rc2-Swift.h"
#import "MCLoginController.h"
#import "Rc2Server.h"
#import "Rc2AppConstants.h"
#import "SSKeychain.h"

@interface MCLoginController()
@property (nonatomic, copy) BasicBlock_t completionHandler;
@property (weak) IBOutlet NSPopUpButton *serverPopUp;
@property (copy) NSArray<NSString*> *hosts;
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
	Rc2RestServer *restServer = [Rc2RestServer sharedInstance];
	self.hosts = [restServer restHosts];
	NSString *lastLogin = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastLogin];
	if (lastLogin) {
		self.loginName = lastLogin;
		[self loadPasswordForLogin];
	}
	self.selectedHost = restServer.selectedHost;
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
	__block typeof(self) bself = self;
	Rc2RestServer *restServer = [Rc2RestServer sharedInstance];
	[restServer selectHost:self.selectedHost];
	[restServer login:self.loginName password:self.password handler:^(BOOL success, id results, NSError *error)
	{
		bself.isBusy=NO;
		if (success) {
			if (restServer.loginSession) {
				[bself.window orderOut:self];
				bself.completionHandler();
			}
			[bself saveLoginInfo];
		} else {
			[NSAlert displayAlertWithTitle:@"Error" details:error.localizedDescription window:bself.window];
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

@end
