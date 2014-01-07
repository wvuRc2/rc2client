//
//  RCSession.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "Rc2AppConstants.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#import "NSString+SBJSON.h"
#import "NSObject+SBJSON.h"
#endif
#import "RCSessionUser.h"
#import "RCSavedSession.h"
#import "RCList.h"
#import "RCProject.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCImageCache.h"
#import "WebSocket.h"
#import "WebSocketConnectConfig.h"
#import "HandshakeHeader.h"
#import "FMDatabase.h"
#import "FMResultSet.h"

#define kWebSocketTimeOutSeconds 6

NSString *const kMode_Share = @"share";
NSString *const kMode_Control = @"control";
NSString *const kMode_Classroom = @"classroom";

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
@property (nonatomic, strong) FMDatabase *searchEngine;
@property (nonatomic, copy) NSString *webTmpFileDirectory;
@property (nonatomic, assign, readwrite) BOOL socketOpen;
@property (nonatomic, assign, readwrite) BOOL hasReadPerm;
@property (nonatomic, assign, readwrite) BOOL hasWritePerm;
@property (nonatomic, strong) NSTimer *keepAliveTimer;
@property (nonatomic, strong) NSDate *timeOfLastTraffic;
@property (nonatomic, strong) NSMutableDictionary *listVariableCallbacks;
#if TARGET_OS_IPHONE
@property (nonatomic, strong) dispatch_queue_t searchQueue;
#else
//10.7 doesn't support queues with ARC so this will leak
@property (nonatomic, strong) __attribute__((NSObject)) dispatch_queue_t searchQueue;
#endif
-(void)keepAliveTimerFired:(NSTimer*)timer;
@end

NSString *const kOutputColorKey_Input = @"OutputColor_Input";
NSString *const kOutputColorKey_Help = @"OutputColor_Help";
NSString *const kOutputColorKey_Status = @"OutputColor_Status";
NSString *const kOutputColorKey_Error = @"OutputColor_Error";
NSString *const kOutputColorKey_Log = @"OutputColor_Log";
NSString *const kOutputColorKey_Note = @"OutputColor_Note";

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
		for (NSString *akey in @[kOutputColorKey_Error, kOutputColorKey_Help, kOutputColorKey_Input, kOutputColorKey_Log, kOutputColorKey_Status, kOutputColorKey_Note]) {
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
	if (self.webTmpFileDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:self.webTmpFileDirectory error:nil];
		self.webTmpFileDirectory=nil;
	}
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

#pragma mark - remote calls

-(void)requestListVariableData:(RCList*)list block:(RCSessionListUpdateBlock)block
{
	if (nil == self.listVariableCallbacks)
		self.listVariableCallbacks = [NSMutableDictionary dictionary];
	NSString *uuid = [NSString stringWithUUID];
	[self.listVariableCallbacks setObject:@{@"block":[block copy],@"list":list} forKey:uuid];
	[_ws sendText:[@{@"cmd":@"getVariable", @"variable":list.fullyQualifiedName, @"uuid":uuid} JSONRepresentation]];
	self.timeOfLastTraffic = [NSDate date];
}

-(void)requestModeChange:(NSString*)newMode
{
	[_ws sendText:[@{@"cmd":@"setmode", @"mode":newMode} JSONRepresentation]];
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

#pragma mark - services for higher layers

-(NSDictionary*)outputAttributesForKey:(NSString*)key
{
	return [self.outputColors objectForKey:key];
}

-(NSString*)pathForCopyForWebKitDisplay:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (nil == self.webTmpFileDirectory) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		[fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *ext = @"txt";
	if (NSOrderedSame == [file.name.pathExtension caseInsensitiveCompare:@"html"])
		ext = @"html";
	NSString *newPath = [[self.webTmpFileDirectory stringByAppendingPathComponent:file.name] stringByAppendingPathExtension:ext];
	NSError *err=nil;
	if ([fm fileExistsAtPath:newPath])
		[fm removeItemAtPath:newPath error:nil];
	if (![fm fileExistsAtPath:file.fileContentsPath]) {
		NSString *fileContents = [[Rc2Server sharedInstance] fetchFileContentsSynchronously:file];
		if (![fileContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
			Rc2LogError(@"failed to write web tmp file:%@", err);
	} else if (![fm copyItemAtPath:file.fileContentsPath toPath:newPath error:&err]) {
		Rc2LogError(@"error copying file:%@", err);
	}
	return newPath;
}

#pragma mark - file content search

-(void)initializeSearchEngine
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		self.searchQueue = dispatch_queue_create("rc2.search", NULL);
		NSString *sePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithUUID]];
		sePath = [sePath stringByAppendingPathExtension:@"db"];
		NSFileManager *fm = [[NSFileManager alloc] init];
		if ([fm fileExistsAtPath:sePath])
			[fm removeItemAtPath:sePath error:nil];
		FMDatabase *db = [[FMDatabase alloc] initWithPath:sePath];
		[db open];
		if (![db executeUpdate:@"create virtual table filetext using fts4(fid, title, content, tokenize=porter)"]) {
			//report error
			Rc2LogError(@"failed to create table for search engine: %@", db.lastErrorMessage);
			return;
		}
		db.shouldCacheStatements = YES;
		NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
		NSMutableArray *files = [self.workspace.project.files mutableCopy];
		[files addObjectsFromArray:self.workspace.files];
		for (RCFile *aFile in files) {
			if (aFile.fileType.isTextFile) {
				[db executeUpdate:@"insert into filetext (fid, title, content) values (?, ?, ?)", aFile.fileId,
				 aFile.name, aFile.currentContents];
			}
		}
		Rc2LogInfo(@"session search indexing took %1.6f sec", CFAbsoluteTimeGetCurrent() - startTime);
		self.searchEngine = db;
	});
}

-(void)searchFiles:(NSString*)searchString handler:(BasicBlock1Arg)searchHandler
{
	if (nil == self.searchEngine)
		[self initializeSearchEngine];
	dispatch_async(self.searchQueue, ^{
		NSLog(@"searching:%@", searchString);
		FMResultSet *rs = [self.searchEngine executeQuery:@"select fid, snippet(filetext,'<b>','</b>','…') from filetext where filetext match ?",
						   searchString];
		NSMutableArray *results = [NSMutableArray array];
		NSError *err;
		NSDictionary *attrs = @{NSBackgroundColorAttributeName:[ColorClass colorWithHexString:kPref_SearchResultBGColor]};
		NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"<b>(.*?)</b>" options:NSRegularExpressionCaseInsensitive error:&err];
		ZAssert(regex, @"bad regex:%@", err);
		while ([rs next]) {
			RCFile *file = [self.workspace fileWithId:[rs objectForColumnIndex:0]];
			if (file) {
				NSString *rawString = [rs objectForColumnIndex:1];
				rawString = [rawString replaceString:@"\n" withString:@" "];
				NSMutableAttributedString *snip = [[NSMutableAttributedString alloc] initWithString:rawString];
				NSArray *matches = [regex matchesInString:rawString options:0 range:NSMakeRange(0, rawString.length)];
				for (NSTextCheckingResult *result in [matches reverseObjectEnumerator]) {
					NSString *matchStr = [rawString substringWithRange:[result rangeAtIndex:1]];
					[snip replaceCharactersInRange:result.range withAttributedString:[[NSAttributedString alloc] initWithString:matchStr attributes:attrs]];
				}
				[regex enumerateMatchesInString:snip.string options:0 range:NSMakeRange(0, snip.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
				{
					[snip addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleThick) range:[result rangeAtIndex:1]];
				}];
				[results addObject:@{@"file":file,@"snippet":snip}];
			}
		}
		[rs close];
		dispatch_async(dispatch_get_main_queue(), ^{
			searchHandler(results);
		});
	});
}


#pragma mark - meat & potatos

-(void)setDelegate:(id<RCSessionDelegate>)del
{
	ZAssert(nil == del || [del conformsToProtocol:@protocol(RCSessionDelegate)], @"delegate not valid");
	_delegate = del;
}

-(void)requestVariables
{
	if (self.socketOpen) {
		NSDictionary *dict = @{@"cmd":@"watchvariables", @"watch": [NSNumber numberWithBool:_variablesVisible]};
		[_ws sendText:[dict JSONRepresentation]];
	}
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

-(void)handleVariableValue:(NSDictionary*)dict
{
	NSDictionary *cbackDict = [self.listVariableCallbacks objectForKey:dict[@"uuid"]];
	if (cbackDict) {
		RCSessionListUpdateBlock block = cbackDict[@"block"];
		RCList *list = cbackDict[@"list"];
		[list assignListData:dict[@"value"]];
		block(list);
		[self.listVariableCallbacks removeObjectForKey:dict[@"uuid"]];
	}
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
	if ([cmd isEqualToString:@"userid"]) {
		self.userid = [dict objectForKey:@"userid"];
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		[self setMode:[dict valueForKeyPath:@"session.mode"]];
	} else if ([cmd isEqualToString:@"note"]) {
		NSString *noteStr = [dict[@"note"] stringByAppendingString:@"\n"];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:noteStr attributes:self.outputColors[kOutputColorKey_Note]]];
	} else if ([cmd isEqualToString:@"echo"]) {
		[self echoInput:dict[@"script"] username:dict[@"username"] user:dict[@"user"]];
	} else if ([cmd isEqualToString:@"error"]) {
		[self appendError:dict[@"error"]];
	} else if ([cmd isEqualToString:@"join"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		NSString *joinstr = [NSString stringWithFormat:@"[%@] %@ joined the session\n", [self.dateFormatter stringFromDate:[NSDate date]], dict[@"user"]];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:joinstr attributes:self.outputColors[kOutputColorKey_Status]]];
	} else if ([cmd isEqualToString:@"left"]) {
		[self updateUsers:[dict valueForKeyPath:@"session.users"]];
		NSString *lefstr = [NSString stringWithFormat:@"[%@] %@ left the session\n", [self.dateFormatter stringFromDate:[NSDate date]], dict[@"user"]];
		[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:lefstr attributes:self.outputColors[kOutputColorKey_Status]]];
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
	} else if ([cmd isEqualToString:@"variablevalue"]) {
		[self handleVariableValue:dict];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpstr = [NSString stringWithFormat:@"HELP: %@\n", dict[@"helpTopic"]];
			NSString *helpPath = [[[dict objectForKey:@"helpPath"] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if (helpPath.length > 0) {
				[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:helpstr attributes:self.outputColors[kOutputColorKey_Help]]];
				NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.stat.wvu.edu/rc2/%@.html", helpPath]];
				[self.delegate loadHelpURL:helpUrl];
			} else {
				[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"No help available for \"%@\"", helpstr] attributes:self.outputColors[kOutputColorKey_Help]]];
				[self.delegate loadHelpURL:nil]; //lets it handle per platform (i.e. beep on mac)
			}
		} else if ([dict objectForKey:@"complexResults"]) {
NSLog(@"complexResults!");
		} else if ([dict objectForKey:@"json"]) {
			NSLog(@"json results!");
		} else if ([dict objectForKey:@"stdout"]) {
			if ([dict objectForKey:@"command"]) {
				[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:dict[@"command"] attributes:self.outputColors[kOutputColorKey_Input]]];
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
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
				NSMutableAttributedString *mgstr = [graphStr mutableCopy];
				[mgstr addAttribute:NSToolTipAttributeName value:imgDict[@"name"] range:NSMakeRange(0, 1)];
				graphStr = mgstr;
#endif
				[mstr appendAttributedString:graphStr];
			}
			[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
			[self.delegate appendAttributedString:mstr];
		}
		if ([dict objectForKey:@"files"])
			[self appendFiles:dict[@"files"]];
		if (self.variablesVisible && [dict objectForKey:@"variables"])
			[self updateVariables:[dict objectForKey:@"variables"] isDelta:[[dict objectForKey:@"delta"] boolValue]];
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		[self appendFiles:@[dict]];
		[self.workspace updateFileId:dict[@"fileId"]];
	} else if ([cmd isEqualToString:@"sasoutput"]) {
		[self appendFiles:dict[@"files"]];
		if (dict[@"error"])
			[self appendError:dict[@"error"]];
	} else {
		Rc2LogWarn(@"unknown message received:%@", dict);
	}
}

#pragma mark - data formatting

-(void)appendFiles:(NSArray*)fileInfo
{
	NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] init];
	[mstr replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\n"];
	RCFile *lastFile;
	for (NSDictionary *fileDict in fileInfo) {
		lastFile = [self.workspace updateFileId:fileDict[@"fileId"]]; //triggers refresh from server
		Rc2FileType *ftype = [Rc2FileType fileTypeWithExtension:fileDict[@"ext"]];
		NSTextAttachment *tattach = [self.delegate textAttachmentForFileId:fileDict[@"fileId"] name:fileDict[@"name"] fileType:ftype];
		NSAttributedString *graphStr = [NSAttributedString attributedStringWithAttachment:tattach];
		[mstr appendAttributedString:graphStr];
		[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:[fileDict[@"name"] stringByAppendingString:@" "]]];
	}
	[mstr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
	[self.delegate appendAttributedString:mstr];
	if (fileInfo.count == 1) {
		[self.delegate displayOutputFile:lastFile];
	}
}

-(void)appendError:(NSString*)error
{
	NSString *errstr = [error stringByAppendingString:@"\n"];
	[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:errstr attributes:self.outputColors[kOutputColorKey_Error]]];
}

-(void)echoInput:(NSString*)script username:(NSString*)username user:(NSString*)user
{
	NSMutableString *str = [[NSMutableString alloc] init];
	if (username)
		[str appendFormat:@"%@:", username];
	[str appendString:script];
	[str appendString:@"\n"];
	[self.delegate appendAttributedString:[[NSAttributedString alloc] initWithString:str attributes:self.outputColors[kOutputColorKey_Input]]];
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
	if (self.variablesVisible)
		[self requestVariables];
	[self.delegate connectionOpened];
	[self initializeSearchEngine];
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
		[self requestVariables];
	}
}

-(BOOL)isClassroomMode
{
	return [self.mode isEqualToString:kMode_Classroom];
}

@end

