//
//  RCSession.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCSession.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"
#endif
#import "RCSessionUser.h"
#import "RCSavedSession.h"

@interface RCSession() {
	NSMutableDictionary *_settings;
	WebSocket07 *_ws;
}
@property (nonatomic, copy, readwrite) NSArray *users;
@property (nonatomic, strong, readwrite) RCSessionUser *currentUser;
@property (nonatomic, strong, readwrite) NSString *mode;
@property (nonatomic, assign, readwrite) BOOL socketOpen;
@property (nonatomic, assign, readwrite) BOOL hasReadPerm;
@property (nonatomic, assign, readwrite) BOOL hasWritePerm;
@property (nonatomic, strong) NSTimer *keepAliveTimer;
@property (nonatomic, strong) NSDate *timeOfLastTraffic;
-(void)keepAliveTimerFired:(NSTimer*)timer;
@end

@implementation RCSession
@synthesize workspace=_workspace;
@synthesize delegate=_delegate;
@synthesize userid=_userid;
@synthesize socketOpen=_socketOpen;
@synthesize hasReadPerm;
@synthesize hasWritePerm;
@synthesize timeOfLastTraffic;
@synthesize keepAliveTimer;
@synthesize initialFileSelection;
@synthesize users;
@synthesize currentUser;
@synthesize mode=_mode;
@synthesize restrictedMode;

- (id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp
{
    self = [super init];
    if (self) {
        _workspace = wspace;
		_settings = [[NSMutableDictionary alloc] init];
		self.users = [NSArray array];
		NSString *settingKey = [NSString stringWithFormat:@"session_%@", self.workspace.wspaceId];
		[_settings setValuesForKeysWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:settingKey]];
		if (rsp)
			[self updateWithServerResponse:rsp];
		self.keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(keepAliveTimerFired:) userInfo:nil repeats:YES];
    }
    return self;
}

-(void)dealloc
{
	_delegate=nil; //assert in setDelegate: would cause crash
	[self.keepAliveTimer invalidate];
	[self closeWebSocket];
	[self removeAllBlockObservers];
}

-(void)updateWithServerResponse:(NSDictionary*)rsp
{
	self.hasReadPerm = [[rsp objectForKey:@"readperm"] boolValue];
	self.hasWritePerm = [[rsp objectForKey:@"writeperm"] boolValue];
}

-(void)startWebSocket
{
	if (_ws)
		return;
	//FIXME: skanky hack
//	NSString *baseUrl = [[Rc2Server sharedInstance] baseUrl];
	NSString *urlStr = [[Rc2Server sharedInstance] websocketUrl];
//	NSString *urlStr = [baseUrl stringByReplacingOccurrencesOfString:@"http" withString:@"ws"];
//	urlStr = [urlStr stringByAppendingString:@"iR/ws"];
	id build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	urlStr = [urlStr stringByAppendingFormat:@"?wid=%@&client=osx&build=%@", self.workspace.wspaceId, build];
#else
	urlStr = [urlStr stringByAppendingFormat:@"?wid=%@&client=ios&build=%@", self.workspace.wspaceId, build];
#endif
	_ws = [WebSocket07 webSocketWithURLString:urlStr delegate:self origin:nil 
									 protocols:nil tlsSettings:nil verifyHandshake:YES];
	_ws.timeout = -1;
	[_ws open];
	RunAfterDelay(10, ^{
		if (!self.socketOpen && _ws) {
			//failed to open after 10 seconds. treat as an error
			[_ws close];
			_ws = nil;
			[self.delegate handleWebSocketError:nil];
		}
	});
}

-(void)closeWebSocket
{
	[_ws close];
	_ws=nil;
}

-(void)requestModeChange:(NSString*)newMode
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"setmode", @"cmd", newMode, @"mode", nil];
	Rc2LogInfo(@"changing mode: %@", newMode);
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)executeSweave:(NSString*)fname script:(NSString*)script
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"sweave", @"cmd", fname, @"fname",
						  script, @"script", nil];
	Rc2LogInfo(@"executing sweave: %@", fname);
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)executeScript:(NSString*)script
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"executeScript", @"cmd",
						  script, @"script", nil];
	Rc2LogInfo(@"executing script: %@", [script length] > 10 ? [[script substringToIndex:10] stringByAppendingString:@"..."] : script);
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)sendChatMessage:(NSString *)message
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"chat", @"cmd",
						  message, @"message", nil];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)requestUserList
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"userlist", @"cmd", nil];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)setDelegate:(id<RCSessionDelegate>)del
{
	ZAssert(nil == del || [del conformsToProtocol:@protocol(RCSessionDelegate)], @"delegate not valid");
	_delegate = del;
}

-(id)savedSessionState
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:self.workspace];
	if (nil == savedState) {
		savedState = [RCSavedSession insertInManagedObjectContext:moc];
		savedState.login = [Rc2Server sharedInstance].currentLogin;
		savedState.wspaceId = self.workspace.wspaceId;
	}
	return savedState;
}

-(void)keepAliveTimerFired:(NSTimer*)timer
{
	if (self.socketOpen && fabs([self.timeOfLastTraffic timeIntervalSinceNow]) > 120) {
		//send a dummy message that will be ignored
		[_ws sendText:@"{cmd:\"keepAlive\"}"];
		self.timeOfLastTraffic = [NSDate date];
	}
}

-(void)updateUsers:(NSArray*)updatedUsers
{
	[self willChangeValueForKey:@"users"];
	NSMutableArray *ma = [NSMutableArray array];
	for (NSDictionary *dict in updatedUsers) {
		RCSessionUser *suser = [[RCSessionUser alloc] initWithDictionary:dict];
		[ma addObject:suser];
		if ([suser.userId isEqualToNumber:self.userid])
			self.currentUser = suser;
	}
	self.users = ma;
	[self didChangeValueForKey:@"users"];
	//TODO: record who's in control
}

-(void)internallyProcessMessage:(NSDictionary*)dict json:(NSString*)json
{
	NSString *cmd = [dict objectForKey:@"msg"];
	if ([cmd isEqualToString:@"userid"]) {
		self.userid = [dict objectForKey:@"userid"];
		[self setMode:[dict valueForKeyPath:@"session.mode"]];
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
	} else if ([cmd isEqualToString:@"join"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
	} else if ([cmd isEqualToString:@"left"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
	} else if ([cmd isEqualToString:@"userlist"]) {
		[self updateUsers:[dict valueForKeyPath:@"data.users"]];
		[self setMode:[dict valueForKeyPath:@"data.mode"]];
	} else if ([cmd isEqualToString:@"modechange"]) {
		[self setMode:[dict objectForKey:@"mode"]];
	}
}

#pragma mark - websocket delegate

-(void)didOpen
{
	NSLog(@"ws open");
	self.socketOpen = YES;
	[self.delegate connectionOpened];
}

- (void) didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError;
{
	NSLog(@"ws close");
	self.socketOpen = NO;
	[self.delegate connectionClosed];
}

- (void) didReceiveError:(NSError*) error
{
	[self.delegate handleWebSocketError:error];
}

//-(void)didReceiveTextMessage:(NSString*)msg
-(void)didReceiveTextMessage:(NSString*)msg
{
	NSDictionary *dict = [msg JSONValue];
	[self internallyProcessMessage:dict json:msg];
	[self.delegate processWebSocketMessage:dict json:msg];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)didReceiveBinaryMessage:(NSData*) aMessage
{
	
}

#pragma mark - settings

-(id)settingForKey:(NSString*)key
{
	return [_settings objectForKey:key];
}

-(void)setSetting:(id)val forKey:(NSString*)key
{
	if ([val isEqual:[_settings objectForKey:key]])
		return;
	[_settings setObject:val forKey:key];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_settings forKey:[NSString stringWithFormat:@"session_%@", self.workspace.wspaceId]];
}

-(void)setMode:(NSString*)theMode
{
	_mode = [theMode copy];
	self.restrictedMode = ![theMode isEqualToString:kMode_Share] && !(self.currentUser.master || self.currentUser.control);
}

@end
