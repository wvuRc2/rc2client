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
#import "RCImageCache.h"
#import "WebSocket.h"
#import "WebSocketConnectConfig.h"
#import "HandshakeHeader.h"

@interface RCSession() <WebSocketDelegate> {
	NSMutableDictionary *_settings;
	WebSocket *_ws;
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
	WebSocketConnectConfig * config = [WebSocketConnectConfig config];
	config.url = [NSURL URLWithString:urlStr];
	config.timeout = -1;
	config.keepAlive = 10.0;
	config.maxPayloadSize = 1024;
	config.version = WebSocketVersion07;
	config.headers = [NSMutableArray array];
	//add cookies
	NSArray *cks = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:config.url];
	NSDictionary *cookies = [NSHTTPCookie requestHeaderFieldsWithCookies:cks];
	NSString *cookieHeader = [cookies objectForKey:@"Cookie"];
	[config.headers addObject:[HandshakeHeader headerWithValue:cookieHeader forKey:@"Cookie"]];
	[config.headers addObject:[HandshakeHeader headerWithValue:@"1" forKey:@"Rc2-API-Version"]];
	_ws = [WebSocket webSocketWithConfig:config delegate:self];
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

-(NSString*)escapeForJS:(NSString*)str
{
	if ([str isKindOfClass:[NSString class]]) {
		str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		return [str stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	}
	return [str description];
}

-(void)internallyProcessMessage:(NSDictionary*)dict json:(NSString*)json
{
	NSString *cmd = [dict objectForKey:@"msg"];
	NSString *js=@"";
	if ([cmd isEqualToString:@"userid"]) {
		self.userid = [dict objectForKey:@"userid"];
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		[self setMode:[dict valueForKeyPath:@"session.mode"]];
		js = [NSString stringWithFormat:@"iR.setUserid(%@)", [dict objectForKey:@"userid"]];
	} else if ([cmd isEqualToString:@"echo"]) {
		js = [NSString stringWithFormat:@"iR.echoInput('%@', '%@', %@)", 
			  [self escapeForJS:[dict objectForKey:@"script"]],
			  [self escapeForJS:[dict objectForKey:@"username"]],
			  [self escapeForJS:[dict objectForKey:@"user"]]];
	} else if ([cmd isEqualToString:@"error"]) {
		NSString *errmsg = [[dict objectForKey:@"error"] stringByTrimmingWhitespace];
		errmsg = [self escapeForJS:errmsg];
		if ([errmsg indexOf:@"\n"] > 0) {
			errmsg = [errmsg stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			js = [NSString stringWithFormat:@"iR.displayFormattedError('%@')", errmsg];
		} else {
			js = [NSString stringWithFormat:@"iR.displayError('%@')", errmsg];
		}
	} else if ([cmd isEqualToString:@"join"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		js = [NSString stringWithFormat:@"iR.userJoinedSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"left"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		js = [NSString stringWithFormat:@"iR.userLeftSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
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
	} else if ([cmd isEqualToString:@"variableupdate"]) {
		[self.delegate variablesUpdated:[dict objectForKey:@"variables"] isDelta:[[dict objectForKey:@"delta"] boolValue]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpPath = [dict objectForKey:@"helpPath"];
			NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://rc2.stat.wvu.edu/Rdocs/%@.html", helpPath]];
			[self.delegate loadHelpURL:helpUrl];
			js = [NSString stringWithFormat:@"iR.appendHelpCommand('%@', '%@')", 
				  [self escapeForJS:[dict objectForKey:@"helpTopic"]],
				  [self escapeForJS:helpUrl.absoluteString]];
		} else if ([dict objectForKey:@"complexResults"]) {
			js = [NSString stringWithFormat:@"iR.appendComplexResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"json"]) {
			js = [NSString stringWithFormat:@"iR.appendResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"stdout"]) {
			NSString *sostr = [self escapeForJS:[dict objectForKey:@"string"]];
			//FIXME: this seems buggy. seems like all \ escapes need to be re-escaped or we need to send json or something encoded
			sostr = [sostr stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			js = [NSString stringWithFormat:@"iR.echoStdout('%@')", sostr];
		}
		if ([[dict objectForKey:@"imageUrls"] count] > 0) {
			NSArray *adjustedImages = [[RCImageCache sharedInstance] adjustImageArray:[dict objectForKey:@"imageUrls"]];
			js = [NSString stringWithFormat:@"iR.appendImages(%@)",
				  [adjustedImages JSONRepresentation]];
		}
		if ([[dict objectForKey:@"files"] count] > 0) {
			NSArray *fileInfo = [dict objectForKey:@"files"];
			for (NSDictionary *fd in fileInfo) {
				[self.workspace updateFileId:[fd objectForKey:@"fileId"]];
			}
			js = [js stringByAppendingFormat:@"\niR.appendFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
		}
		if (self.variablesVisible && [dict objectForKey:@"variables"])
			[self.delegate variablesUpdated:[dict objectForKey:@"variables"] isDelta:[[dict objectForKey:@"delta"] boolValue]];
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		NSNumber *fileid = [dict objectForKey:@"fileId"];
		js = [NSString stringWithFormat:@"iR.appendPdf('%@', %@, '%@')", [self escapeForJS:[dict objectForKey:@"pdfurl"]], fileid,
			  [self escapeForJS:[dict objectForKey:@"filename"]]];
		[self.workspace updateFileId:fileid];
	} else if ([cmd isEqualToString:@"sasoutput"]) {
		NSArray *fileInfo = [dict objectForKey:@"files"];
		for (NSDictionary *fd in fileInfo) {
			[self.workspace updateFileId:[fd objectForKey:@"fileId"]];
		}
		js = [NSString stringWithFormat:@"iR.appendFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
	}
	if ([js length] > 0)
		[self.delegate executeJavascript:js];
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
	_ws=nil;
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

#pragma mark - accessors

-(void)setMode:(NSString*)theMode
{
	_mode = [theMode copy];
	self.restrictedMode = ![theMode isEqualToString:kMode_Share] && !(self.currentUser.master || self.currentUser.control);
}

-(void)setVariablesVisible:(BOOL)visible
{
	if (_variablesVisible != visible) {
		_variablesVisible = visible;
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"watchvariables", @"cmd", [NSNumber numberWithBool:visible], @"watch", nil];
		[_ws sendText:[dict JSONRepresentation]];
	}
}

-(BOOL)isClassroomMode
{
	return [self.mode isEqualToString:kMode_Classroom];
}

@end
