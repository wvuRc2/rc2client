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
#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"
#import "RCSavedSession.h"

@interface RCSession() {
	NSMutableDictionary *_settings;
	WebSocket00 *_ws;
}
@property (nonatomic, assign, readwrite) BOOL socketOpen;
@end

@implementation RCSession
@synthesize workspace=_workspace;
@synthesize delegate=_delegate;
@synthesize userid=_userid;
@synthesize socketOpen=_socketOpen;
@synthesize hasReadPerm=_haveReadPerm;
@synthesize hasWritePerm=_haveWritePerm;

- (id)initWithWorkspace:(RCWorkspace*)wspace serverResponse:(NSDictionary*)rsp
{
    self = [super init];
    if (self) {
        _workspace = [wspace retain];
		_settings = [[NSMutableDictionary alloc] init];
		NSString *settingKey = [NSString stringWithFormat:@"session_%@", self.workspace.wspaceId];
		[_settings setValuesForKeysWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:settingKey]];
		_haveReadPerm = [[rsp objectForKey:@"readperm"] boolValue];
		_haveWritePerm = [[rsp objectForKey:@"writeperm"] boolValue];
    }
    return self;
}

-(void)dealloc
{
	_delegate=nil; //assert in setDelegate: would cause crash
	self.userid=nil;
	[_workspace release];
	[_settings release];
	[super dealloc];
}

-(void)startWebSocket
{
	NSString *baseUrl = [[Rc2Server sharedInstance] baseUrl];
	NSString *urlStr = [baseUrl stringByReplacingOccurrencesOfString:@"http" withString:@"ws"];
	urlStr = [urlStr stringByAppendingString:@"iR/ws"];
	_ws = [[WebSocket00 webSocketWithURLString:urlStr delegate:self origin:nil 
									 protocols:nil tlsSettings:nil verifyHandshake:YES] retain];
	_ws.timeout = -1;
	[_ws open];
}

-(void)closeWebSocket
{
	[_ws close];
	[_ws release];
	_ws=nil;
}

-(void)executeScript:(NSString*)script
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"executeScript", @"cmd",
						  script, @"script", nil];
	[_ws send:[dict JSONRepresentation]];
}

-(void)sendChatMessage:(NSString *)message
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"chat", @"cmd",
						  message, @"message", nil];
	[_ws send:[dict JSONRepresentation]];
}

-(void)setDelegate:(id<RCSessionDelegate>)del
{
	ZAssert([del conformsToProtocol:@protocol(RCSessionDelegate)], @"delegate not valid");
	_delegate = del;
}

-(RCSavedSession*)savedSessionState
{
	NSManagedObjectContext *moc = [[UIApplication sharedApplication] valueForKeyPath:@"delegate.managedObjectContext"];
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:self.workspace];
	if (nil == savedState) {
		savedState = [RCSavedSession insertInManagedObjectContext:moc];
		savedState.login = [Rc2Server sharedInstance].currentLogin;
		savedState.wspaceId = self.workspace.wspaceId;
	}
	return savedState;
}

#pragma mark - websocket delegate

-(void)didOpen
{
	NSLog(@"ws open");
	self.socketOpen = YES;
	[self.delegate connectionOpened];
}

- (void) didClose: (NSError*) aError
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
-(void)didReceiveMessage:(NSString*)msg
{
	NSDictionary *dict = [msg JSONValue];
	NSString *cmd = [dict objectForKey:@"msg"];
	if ([cmd isEqualToString:@"userid"]) {
		self.userid = [dict objectForKey:@"userid"];
	}
	[self.delegate processWebSocketMessage:dict json:msg];
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

@end
