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
#import "RCVariable.h"
#import "RCProject.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCImageCache.h"
#import "WebSocket.h"
#import "WebSocketConnectConfig.h"
#import "HandshakeHeader.h"

#define kWebSocketTimeOutSeconds 6

NSString * const RC2WebSocketErrorDomain = @"RC2WebSocketErrorDomain";

@interface RCSession() <WebSocketDelegate> {
	NSMutableDictionary *_settings;
	WebSocket *_ws;
}
@property (nonatomic, copy) NSDictionary *outputColors;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy, readwrite) NSArray *variables;
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

#define kOColor_Input @"OutputColor_Input"
#define kOColor_Help @"OutputColor_Help"
#define kOColor_Status @"OutputColor_Status"
#define kOColor_Error @"OutputColor_Error"
#define kOColor_Log @"OutputColor_Log"
#define kOColor_Note @"OutputColor_Note"

@implementation RCSession

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
		self.keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(keepAliveTimerFired:) userInfo:nil repeats:YES];
		//load output colors
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary *oc = [NSMutableDictionary dictionary];
		for (NSString *akey in @[kOColor_Error, kOColor_Help, kOColor_Input, kOColor_Log, kOColor_Status, kOColor_Note]) {
			ColorClass *color = [ColorClass colorWithHexString:[defaults objectForKey:akey]];
			if (color)
				[oc setObject:@{NSBackgroundColorAttributeName:color} forKey:akey];
		}
		self.outputColors = oc;
		self.dateFormatter = [[NSDateFormatter alloc] init];
		self.dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
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
	NSString *urlStr = [[Rc2Server sharedInstance] websocketUrl];
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
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060 && defined(DEBUG))
	if ([[Rc2Server sharedInstance] isAdmin]) {
		NSMutableString *str = [NSMutableString string];
		for (NSString *aStr in [cookieHeader componentsSeparatedByString:@"; "]) {
			if ([aStr hasPrefix:@"wspaceid"] || [aStr hasPrefix:@"me"])
				[str appendFormat:@"%@;", aStr];
		}
		NSLog(@"auth cookies:\n%@\n", str);
	}
#endif
	[config.headers addObject:[HandshakeHeader headerWithValue:cookieHeader forKey:@"Cookie"]];
	[config.headers addObject:[HandshakeHeader headerWithValue:@"1" forKey:@"Rc2-API-Version"]];
	_ws = [WebSocket webSocketWithConfig:config delegate:self];
	[_ws open];
	RunAfterDelay(kWebSocketTimeOutSeconds, ^{
		if (!self.socketOpen && _ws) {
			//failed to open after 10 seconds. treat as an error
			[_ws close];
			_ws = nil;
			[self.delegate handleWebSocketError:[NSError errorWithDomain:RC2WebSocketErrorDomain code:kRc2Err_ConnectionTimedOut userInfo:@{NSLocalizedDescriptionKey:@"connection timed out"}]];
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
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)executeScriptFile:(RCFile*)file
{
	[self executeScriptFile:file options:RCSessionExecuteOptionNone];
}

-(void)executeScriptFile:(RCFile*)file options:(RCSessionExecuteOptions)options
{
	NSMutableDictionary *dict = [@{@"cmd":@"executeScriptFile", @"fname":file.name, @"fileId":file.fileId} mutableCopy];
	if (options & RCSessionExecuteOptionSource)
		[dict setObject:@YES forKey:@"source"];
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)executeScript:(NSString*)script scriptName:(NSString*)fname
{
	[self executeScript:script scriptName:fname options:RCSessionExecuteOptionNone];
}

-(void)executeScript:(NSString*)script scriptName:(NSString*)fname options:(RCSessionExecuteOptions)options
{
	//fname or script could be null, so can't use literals
	if (script.stringByTrimmingWhitespace.length < 1)
		return; //don't send empty strings
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:@"executeScript" forKey:@"cmd"];
	if (script)
		[dict setObject:script forKey:@"script"];
	if (fname)
		[dict setObject:fname forKey:@"fname"];
	//the second condtion below is a hack. the server needs to support help output when running with nlAsSemi
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TreatNewlinesAsSemicolons"] && ![fname hasPrefix:@"help("])
		[dict setObject:@YES forKey:@"nlAsSemi"];
	if (options & RCSessionExecuteOptionSource)
		[dict setObject:@YES forKey:@"source"];
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

-(void)restartR
{
	NSDictionary *dict = @{@"cmd":@"restartR"};
	[_ws sendText:[dict JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)clearVariables
{
	[_ws sendText:[@{@"cmd":@"executeScript", @"script":@"rc2.clearEnvironment()"} JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)forceVariableRefresh
{
	NSDictionary *dict = @{@"cmd":@"watchvariables", @"watch": @YES};
	[_ws sendText:[dict JSONRepresentation]];
}

-(void)sendFileOpened:(RCFile*)file fullscreen:(BOOL)fs
{
	NSDictionary *dict = @{@"cmd":@"clcommand", @"subcmd": @"openfile", @"fid":file.fileId};
	[_ws sendText:[dict JSONRepresentation]];
}

-(void)setDelegate:(id<RCSessionDelegate>)del
{
	ZAssert(nil == del || [del conformsToProtocol:@protocol(RCSessionDelegate)], @"delegate not valid");
	_delegate = del;
}

-(BOOL)fileCanBePromotedToAssignment:(RCFile*)file
{
	if (!self.workspace.project.isClass)
		return NO;
	if (!file.fileType.isSourceFile)
		return NO;
	//TODO: need to check if student or teacher
	return YES;
}

-(id)savedSessionState
{
	RCSavedSession *savedState = [[Rc2Server sharedInstance] savedSessionForWorkspace:self.workspace];
	if (nil == savedState) {
		savedState = [RCSavedSession MR_createEntity];
		savedState.login = [Rc2Server sharedInstance].currentLogin;
		savedState.wspaceId = self.workspace.wspaceId;
	}
	return savedState;
}

-(void)keepAliveTimerFired:(NSTimer*)timer
{
	if (self.socketOpen && fabs([self.timeOfLastTraffic timeIntervalSinceNow]) > 120) {
		//send a dummy message that will be ignored
		[_ws sendText:@"{\"cmd\":\"keepAlive\"}"];
		self.timeOfLastTraffic = [NSDate date];
	}
}

-(void)handleModeMessage:(NSDictionary*)dict
{
	NSNumber *ctrl_sid = [dict objectForKey:@"control_sid"];
	if ([ctrl_sid isEqualToNumber:self.currentUser.sid])
		self.currentUser.control = YES;
	[self setMode:[dict objectForKey:@"mode"]];
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

-(void)updateVariables:(NSDictionary*)variableDict isDelta:(BOOL)delta
{
	NSArray *newValues = [variableDict objectForKey:@"values"];
	NSMutableArray *vars = delta ? [self.variables mutableCopy] : [[NSMutableArray alloc] initWithCapacity:newValues.count];
	for (RCVariable *oldVar in vars)
		oldVar.justUpdated = NO;
	for (NSDictionary *aDict in newValues) {
		NSUInteger idx = [self.variables indexOfFirstObjectWithValue:[aDict objectForKey:@"name"] forKey:@"name"];
		RCVariable *var = [RCVariable variableWithDictionary:aDict];
		if (delta && idx != NSNotFound) {
			var.justUpdated = YES;
			[vars replaceObjectAtIndex:idx withObject:var];
		} else {
			if (delta)
				var.justUpdated = YES;
			[vars addObject:var];
		}
	}
	NSArray *delKeys = [variableDict objectForKey:@"deleted"];
	for (NSString *aKey in delKeys) {
		NSUInteger idx = [vars indexOfFirstObjectWithValue:aKey forKey:@"name"];
		if (idx != NSNotFound) {
			[vars removeObjectAtIndex:idx];
		}
	}
	self.variables = vars;
	[self.delegate variablesUpdated];
}

-(NSString*)escapeForJS:(NSString*)str
{
	if ([str isKindOfClass:[NSString class]]) {
		str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
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
	} else if ([cmd isEqualToString:@"note"]) {
		NSString *noteStr = [dict[@"note"] stringByAppendingString:@"\n"];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:noteStr attributes:self.outputColors[kOColor_Note]]];
	} else if ([cmd isEqualToString:@"echo"]) {
		[self echoInput:dict[@"script"] username:dict[@"username"] user:dict[@"user"]];
	} else if ([cmd isEqualToString:@"error"]) {
		[self appendError:dict[@"error"]];
	} else if ([cmd isEqualToString:@"join"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		NSString *joinstr = [NSString stringWithFormat:@"[%@] %@ joined the session\n", [self.dateFormatter stringFromDate:[NSDate date]], dict[@"user"]];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:joinstr attributes:self.outputColors[kOColor_Status]]];
	} else if ([cmd isEqualToString:@"left"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		NSString *lefstr = [NSString stringWithFormat:@"[%@] %@ left the session\n", [self.dateFormatter stringFromDate:[NSDate date]], dict[@"user"]];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:lefstr attributes:self.outputColors[kOColor_Status]]];
	} else if ([cmd isEqualToString:@"userlist"]) {
		[self updateUsers:[dict valueForKeyPath:@"data.users"]];
		[self setMode:[dict valueForKeyPath:@"data.mode"]];
	} else if ([cmd isEqualToString:@"modechange"]) {
		[self handleModeMessage:dict];
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
		if ([dict objectForKey:@"deleted"]) {
			[[Rc2Server sharedInstance] removeFileReferences:file];
			[self.delegate workspaceFileUpdated:file deleted:YES];
		} else {
			if (file) {
				[file updateWithDictionary:[dict objectForKey:@"file"]];
				[self.delegate workspaceFileUpdated:file deleted:NO];
			} else { //a new file
				[self.workspace refreshFiles];
			}
		}
	} else if ([cmd isEqualToString:@"fileupdates"]) {
		BOOL triggerRefresh=NO;
		for (NSNumber *fid in [dict objectForKey:@"fileIds"]) {
			RCFile *file = [self.workspace fileWithId:fid];
			if (file) {
				[file updateWithDictionary:[dict objectForKey:@"file"]];
				[self.delegate workspaceFileUpdated:file deleted:NO];
			} else { //a new file
				triggerRefresh = YES;
			}
		}
		if (triggerRefresh)
			[self.workspace refreshFiles];
	} else if ([cmd isEqualToString:@"variableupdate"]) {
		[self updateVariables:[dict objectForKey:@"variables"] isDelta:[[dict objectForKey:@"delta"] boolValue]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpstr = [NSString stringWithFormat:@"HELP: %@", dict[@"helpTopic"]];
			[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:helpstr attributes:self.outputColors[kOColor_Help]]];
			NSString *helpPath = [dict objectForKey:@"helpPath"];
			NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.stat.wvu.edu/rc2/%@.html", helpPath]];
			[self.delegate loadHelpURL:helpUrl];
		} else if ([dict objectForKey:@"complexResults"]) {
			NSLog(@"complexResults!");
//			if (self.showResultDetails)
//				js = [NSString stringWithFormat:@"iR.appendComplexResults(%@)", [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"json"]) {
			NSLog(@"json results!");
			if (self.showResultDetails)
				js = [NSString stringWithFormat:@"iR.appendResults(%@)", [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"stdout"]) {
			if ([dict objectForKey:@"command"]) {
				[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:dict[@"command"] attributes:self.outputColors[kOColor_Input]]];
			}
			[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:dict[@"string"] attributes:nil]];
		}
		if ([[dict objectForKey:@"imageUrls"] count] > 0) {
			//this call caches the images, so we call even though we don't need the returned array
			[[RCImageCache sharedInstance] cacheImagesWithServerDicts:[dict objectForKey:@"imageUrls"]];
			NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] init];
			for (NSDictionary *imgDict in dict[@"imageUrls"]) {
				NSTextAttachment *tattach = [self.delegate textAttachmentForImageId:imgDict[@"id"] imageUrl:imgDict[@"url"]];
				NSAttributedString *graphStr = [NSAttributedString attributedStringWithAttachment:tattach];
				[mstr appendAttributedString:graphStr];
			}
			[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
			[self.delegate appendAttributedString:mstr];
		}
		if ([[dict objectForKey:@"files"] count] > 0) {
			[self appendFiles:dict[@"files"]];

			/*NSArray *fileInfo = [dict objectForKey:@"files"];
			for (NSDictionary *fd in fileInfo) {
				[self.workspace updateFileId:[fd objectForKey:@"fileId"]];
			}
			js = [js stringByAppendingFormat:@"\niR.appendFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
			//if a single html file returned, queue it up for display
			if (fileInfo.count == 1 && [fileInfo[0][@"ext"] isEqualToString:@".html"]) {
				RunAfterDelay(0.6, ^{
					[self.delegate displayLinkedFile:[NSString stringWithFormat:@"/%@.html", fileInfo[0][@"fileId"]]];
				});
			}
			 */
		}
		if (self.variablesVisible && [dict objectForKey:@"variables"])
			[self updateVariables:[dict objectForKey:@"variables"] isDelta:[[dict objectForKey:@"delta"] boolValue]];
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		[self appendFiles:@[dict]];
		[self.workspace updateFileId:dict[@"fileId"]];
	} else if ([cmd isEqualToString:@"sasoutput"]) {
		[self appendFiles:dict[@"files"]];
		if (dict[@"error"])
			[self appendError:dict[@"error"]];
//		NSArray *fileInfo = [dict objectForKey:@"files"];
//		for (NSDictionary *fd in fileInfo) {
//			[self.workspace updateFileId:[fd objectForKey:@"fileId"]];
//		}
//		js = [NSString stringWithFormat:@"iR.appendFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
//		if ([dict objectForKey:@"error"]) {
//			js = [NSString stringWithFormat:@"iR.displayError('%@'); %@", [self escapeForJS:dict[@"error"]], js];
//		}
	} else {
		Rc2LogWarn(@"unknown message received:%@", dict);
	}
}

#pragma mark - data formatting

-(void)appendFiles:(NSArray*)fileInfo
{
	NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] init];
	[mstr replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\n"];
	for (NSDictionary *fileDict in fileInfo) {
		[self.workspace updateFileId:fileDict[@"fileId"]]; //triggers refresh from server
		Rc2FileType *ftype = [Rc2FileType fileTypeWithExtension:fileDict[@"ext"]];
		NSTextAttachment *tattach = [self.delegate textAttachmentForFileId:fileDict[@"fileId"] name:fileDict[@"name"] fileType:ftype];
		NSAttributedString *graphStr = [NSAttributedString attributedStringWithAttachment:tattach];
		[mstr appendAttributedString:graphStr];
		[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:[fileDict[@"name"] stringByAppendingString:@" "]]];
	}
	[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
	[self.delegate appendAttributedString:mstr];
}

-(void)appendError:(NSString*)error
{
	NSString *errstr = [error stringByAppendingString:@"\n"];
	[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:errstr attributes:self.outputColors[kOColor_Error]]];
}

-(void)echoInput:(NSString*)script username:(NSString*)username user:(NSString*)user
{
	NSMutableString *str = [[NSMutableString alloc] init];
	if (username)
		[str appendFormat:@"%@:", username];
	[str appendString:script];
	[str appendString:@"\n"];
	[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:self.outputColors[kOColor_Input]]];
/*
	NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] init];
	[mstr replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\nboo:\n"];
	NSTextAttachment *tattach = [[NSTextAttachment alloc] initWithData:[@"111" dataUsingEncoding:NSUTF8StringEncoding] ofType:@"rc2.image"];
	tattach.image = [ImageClass imageNamed:@"graph"];
	NSAttributedString *graphStr = [NSAttributedString attributedStringWithAttachment:tattach];
	[mstr appendAttributedString:graphStr];
	[mstr appendAttributedString:graphStr];
	[mstr replaceCharactersInRange:NSMakeRange(mstr.length, 0) withString:@"\n\n"];
	[self.delegate appendAttributedString:mstr];
	NSError *err;
	NSData *d = [mstr dataFromRange:NSMakeRange(0, mstr.length) documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType} error:&err];
	if (err)
		NSLog(@"error:%@", err);
	else {
		NSDictionary *attrs;
		NSAttributedString *astr = [[NSAttributedString alloc] initWithData:d options:Nil documentAttributes:&attrs error:&err];
		[self.delegate appendAttributedString:astr];
	} */
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
		NSDictionary *dict = @{@"cmd":@"watchvariables", @"watch": [NSNumber numberWithBool:_variablesVisible]};
		[_ws sendText:[dict JSONRepresentation]];
	}
}

-(BOOL)isClassroomMode
{
	return [self.mode isEqualToString:kMode_Classroom];
}

@end

