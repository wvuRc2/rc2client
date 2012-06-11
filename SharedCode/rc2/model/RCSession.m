//
//  RCSession.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 West Virginia University. All rights reserved.
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
#import "RCFile.h"

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
@synthesize handRaised;

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

-(void)executeScript:(NSString*)script scriptName:(NSString*)fname
{
	//fname could be null, so at end of list
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"executeScript", @"cmd", script, @"script", 
						  fname, @"fname", nil];
	Rc2LogInfo(@"executing script: %@", [script length] > 10 ? [[script substringToIndex:10] stringByAppendingString:@"..."] : script);
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)executeSas:(RCFile*)file
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"executeSas", @"cmd", file.fileId, @"fileId", 
						  file.name, @"fname", nil];
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

-(void)sendAudioInput:(NSData*)data
{
	[_ws sendBinary:data];
}

-(void)requestUserList
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"userlist", @"cmd", nil];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)raiseHand
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"raisehand", @"cmd", nil];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)lowerHand
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"lowerhand", @"cmd", nil];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)sendFileOpened:(RCFile*)file
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"clcommand", @"cmd", @"openfile", @"subcmd",
						  file.fileId, @"fid", nil];
	[_ws sendText:[dict JSONRepresentation]];
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

-(RCSessionUser*)userWithSid:(NSNumber*)sid
{
	for (RCSessionUser *user in self.users) {
		if ([user.sid isEqualToNumber:sid])
			return user;
	}
	return nil;
}

-(void)updateUsers:(NSArray*)updatedUsers
{
	[self willChangeValueForKey:@"users"];
	NSMutableArray *ma = [NSMutableArray array];
	for (NSDictionary *dict in updatedUsers) {
		RCSessionUser *suser = [self userWithSid:[dict objectForKey:@"sid"]];
		if (nil == suser)
			suser = [[RCSessionUser alloc] initWithDictionary:dict];
		[ma addObject:suser];
		if ([suser.userId isEqualToNumber:self.userid])
			self.currentUser = suser;
	}
	self.users = ma;
	[self didChangeValueForKey:@"users"];
}

-(void)internallyProcessMessage:(NSDictionary*)dict json:(NSString*)json
{
	NSString *cmd = [dict objectForKey:@"msg"];
	if ([cmd isEqualToString:@"userid"]) {
		self.userid = [dict objectForKey:@"userid"];
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		[self setMode:[dict valueForKeyPath:@"session.mode"]];
	} else if ([cmd isEqualToString:@"join"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
	} else if ([cmd isEqualToString:@"left"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
	} else if ([cmd isEqualToString:@"userlist"]) {
		[self updateUsers:[dict valueForKeyPath:@"data.users"]];
		[self setMode:[dict valueForKeyPath:@"data.mode"]];
	} else if ([cmd isEqualToString:@"modechange"]) {
		[self setMode:[dict objectForKey:@"mode"]];
	} else if ([cmd isEqualToString:@"handraised"]) {
		[self willChangeValueForKey:@"users"];
		[self userWithSid:[dict objectForKey:@"sid"]].handRaised = YES;
		if ([[dict objectForKey:@"sid"] isEqualToNumber:self.currentUser.sid])
			self.handRaised = YES;
		[self didChangeValueForKey:@"users"];
	} else if ([cmd isEqualToString:@"handlowered"]) {
		[self willChangeValueForKey:@"users"];
		[self userWithSid:[dict objectForKey:@"sid"]].handRaised = NO;
		if ([[dict objectForKey:@"sid"] isEqualToNumber:self.currentUser.sid])
			self.handRaised = NO;
		[self didChangeValueForKey:@"users"];
	} else if ([cmd isEqualToString:@"clopenfile"]) {
		RCFile *file = [self.workspace fileWithId:[dict objectForKey:@"fileId"]];
		[self.delegate displayEditorFile:file];
	} else if ([cmd isEqualToString:@"fileupdate"]) {
		RCFile *file = [self.workspace fileWithId:[dict objectForKey:@"fileId"]];
		if (file) {
			[file updateWithDictionary:[dict objectForKey:@"file"]];
			[self.delegate workspaceFileUpdated:file];
		} else { //a new file
			[self.workspace refreshFiles];
		}
	}
}

#pragma mark - websocket delegate

-(void)didOpen
{
	self.socketOpen = YES;
	[self.delegate connectionOpened];
}

- (void) didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError;
{
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
	[self.delegate processBinaryMessage:aMessage];
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

-(BOOL)isClassroomMode
{
	return [self.mode isEqualToString:kMode_Classroom];
}

@end
