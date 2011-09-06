//
//  MacLoginController.m
//  MacClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacLoginController.h"
#import "Rc2Server.h"
#import "EMKeychainItem.h"

#define kLastLoginKey @"LastLogin"
#define kLastServerKey @"LastServer"


@interface MacLoginController()
@property (nonatomic, copy) BasicBlock_t completionHandler;
-(void)saveLoginInfo;
-(void)loadPasswordForLogin;
-(NSString*)selectedHost;
@end

@implementation MacLoginController

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MacLoginController"])) {
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	NSString *lastLogin = [[NSUserDefaults standardUserDefaults] objectForKey:kLastLoginKey];
	if (lastLogin) {
		self.loginName = lastLogin;
		[self loadPasswordForLogin];
	}
	self.selectedServerIdx = [[NSUserDefaults standardUserDefaults] integerForKey:kLastServerKey];
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
	[Rc2Server sharedInstance].serverHost = self.selectedServerIdx;
	__block MacLoginController *blockSelf = self;
	[[Rc2Server sharedInstance] loginAsUser:self.loginName password:self.password
		completionHandler:^(BOOL success, NSString *message) 
		{
			blockSelf.isBusy=NO;
			if (success) {
				if ([Rc2Server sharedInstance].loggedIn) {
					[blockSelf.window orderOut:self];
					blockSelf.completionHandler();
				}
				[blockSelf saveLoginInfo];
			} else {
				//FIXME: need to report error
				NSLog(@"ERROR");
			}
		}];
}

-(void)saveLoginInfo
{
	[[NSUserDefaults standardUserDefaults] setInteger:self.selectedServerIdx forKey:kLastServerKey];
	@try {
		EMGenericKeychainItem *ki = [EMGenericKeychainItem genericKeychainItemForService:@"rc2" withUsername:self.loginName];
		if (ki) {
			ki.password = self.password;
		} else {
			[EMGenericKeychainItem addGenericKeychainItemForService:@"rc2" withUsername:self.loginName password:self.password];
		}
		[[NSUserDefaults standardUserDefaults] setObject:self.loginName forKey:kLastLoginKey];
	} @catch (NSException *e) {
		NSLog(@"got exception %@", [e reason]);
	}
}

-(void)loadPasswordForLogin
{
	EMGenericKeychainItem *ki = [EMGenericKeychainItem genericKeychainItemForService:@"rc2" withUsername:self.loginName];
	if (ki)
		self.password = ki.password;
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
						  
@synthesize password;
@synthesize selectedServerIdx;
@synthesize isBusy;
@synthesize completionHandler;
@synthesize loginName;
@end
