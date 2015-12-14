//
//  Rc2RestServer.m
//  Rc2Client
//
//  Created by Mark Lilback on 12/10/15.
//  Copyright © 2015 West Virginia University. All rights reserved.
//

#import "Rc2RestServer.h"
#import "Rc2AppConstants.h"
#import "NSArray+Rc2Extensions.h"
#import "Rc2-Swift.h"

static Rc2RestServer *sInstance;
static NSString *const kServerHostKey = @"ServerHostKey";

///posted on login and logout with the object being the Rc2RestServer instance
NSString * const Rc2RestLoginStatusChangedNotification = @"Rc2RestLoginStatusChangedNotification";


@interface Rc2RestServer ()
@property (nonatomic, strong) NSURLSessionConfiguration *urlConfig;
@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, strong, readwrite) Rc2LoginSession *loginSession;
@property (nonatomic, copy) NSArray *hosts;
@property (nonatomic, copy) NSURL *baseUrl;
@end

@implementation Rc2RestServer
+(instancetype)sharedInstance {
	if (nil == sInstance) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			sInstance = [[Rc2RestServer alloc] init];
		});
	}
	return sInstance;
}

+(void)setSharedInstance:(Rc2RestServer*)server
{
	sInstance = server;
}

-(id)initWithSessionConfiguration:(NSURLSessionConfiguration*)config
{
	if ((self = [super init])) {
		_urlConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
		_urlConfig.HTTPAdditionalHeaders = @{@"User-Agent": [self userAgentString], @"Accept":@"application/json"};
		_urlSession = [NSURLSession sessionWithConfiguration:_urlConfig];
		NSError *err;
		NSURL *hostFileUrl = [[NSBundle mainBundle] URLForResource:@"Rc2RestHosts" withExtension:@"json"];
		NSAssert(hostFileUrl != nil, @"failed to read Rc2RestHosts.json");
		NSData *jsonData = [NSData dataWithContentsOfURL:hostFileUrl];
		NSAssert(jsonData, @"Failed to read json data from Rc2RestHosts file");
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&err];
		self.hosts = [json objectForKey:@"hosts"];
		NSAssert(self.restHosts.count > 0, @"invalid hosts data");
	}
	return self;
}

-(id)init
{
	return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

#pragma mark - basic public methods

-(NSArray<NSString*>*)restHosts
{
	return [self.hosts valueForKeyPath:@"name"];
}

-(NSString*)defaultRestHost
{
	return [[self.hosts objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kServerHostKey]] valueForKey:@"name"];
}

-(NSString*)userAgentString
{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED >= 1090)
	return @"Rc2 MacClient";
#else
	return @"Rc2 iPadClient";
#endif
}

-(NSString*)connectionDescription
{
	NSString *login = [self.loginSession valueForKeyPath:@"currentUser.login"];
	NSString *host = [self.loginSession valueForKey:@"host"];
	if ([host isEqualToString:@"rc2"])
		return login;
	return [NSString stringWithFormat:@"%@@%@", login, host];
}

#pragma mark - internal utility methods

-(NSMutableURLRequest*)requestWithPath:(NSString*)path method:(NSString*)method json:(NSDictionary*)jsonDict
{
	NSError *error;
	NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseUrl];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	req.HTTPMethod = method;
	if (self.loginSession.authToken)
		[req addValue:self.loginSession.authToken forHTTPHeaderField:@"Rc2-Auth"];
	if (jsonDict.count > 0) {
		[req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		req.HTTPBody = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
		if (error)
			Rc2LogError(@"error serialzing to json: %@ (%@)", jsonDict, error.localizedDescription);
	}
	return req;
}

#pragma mark - login/logout

-(void)loginToHostName:(NSString*)hostName login:(NSString*)login password:(NSString*)password handler:(Rc2RestCompletionHandler)handler
{
	//get the host structure
	NSDictionary *hostDict = [self.hosts rc2_firstObjectWithValue:hostName forKey:@"host"];
	if (nil == hostDict) {
		[NSException raise:NSInvalidArgumentException format:@"invalid hostname: %@", hostName];
	}
	NSString *hoststr = [NSString stringWithFormat:@"http%@://%@:%@/",
						 [hostDict[@"secure"] boolValue] ? @"s" : @"",
						 hostDict[@"host"],
						 hostDict[@"port"]];
	self.baseUrl = [NSURL URLWithString:hoststr];
	//setup done, make login request
	NSMutableURLRequest *req = [self requestWithPath:@"login" method:@"POST" json:@{@"login":login, @"password":password}];
	NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
	{
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		if (httpResponse.statusCode == 401) {
			NSError *loginError = [NSError errorWithDomain:Rc2ErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Invalid login or password", @"")}];
			dispatchOnMainQueue( ^{handler(NO, nil, loginError); } );
		} else if (httpResponse.statusCode == 200) {
			self.loginSession = [[Rc2LoginSession alloc] initWithJsonData:json host:hostDict[@"host"]];
			dispatchOnMainQueue( ^{handler(YES, self.loginSession, nil);} );
			NSInteger hostIndex = [self.hosts indexOfObject:hostDict];
			[[NSUserDefaults standardUserDefaults] setInteger:hostIndex forKey:kServerHostKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:Rc2RestLoginStatusChangedNotification object:self];
		} else {
			Rc2LogWarn(@"login got unknown error:%ld", (long)httpResponse.statusCode);
			dispatchOnMainQueue( ^{handler(NO, nil, error); });
		}
	}];
	[task resume];
}

#pragma mark - workspaces

//updates the workspaces array of the loginSession
-(void)createWorkspace:(NSString*)wspaceName completionBlock:(Rc2RestCompletionHandler)handler
{
	NSMutableURLRequest *req = [self requestWithPath:@"workspaces" method:@"POST" json:@{@"name":wspaceName}];
	NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
	{
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		if (httpResponse.statusCode == 200) {
			Rc2Workspace *wspace = [[Rc2Workspace alloc] initWithJsonData:json];
			NSMutableArray *spaces = [self.loginSession.workspaces mutableCopy];
			[spaces addObject:wspace];
			[spaces sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
			self.loginSession.workspaces = spaces;
			dispatchOnMainQueue( ^{handler(YES, wspace, nil);} );
		} else {
			Rc2LogWarn(@"create workspace got unknown error:%ld", (long)httpResponse.statusCode);
			dispatchOnMainQueue( ^{handler(NO, nil, error); });
		}
	}];
	[task resume];
}

-(void)renameWorkspce:(Rc2Workspace*)wspace name:(NSString*)newName completionHandler:(Rc2RestCompletionHandler)handler
{
	NSString *path = [NSString stringWithFormat:@"workspaces/%d", wspace.wspaceId];
	NSMutableURLRequest *req = [self requestWithPath:path method:@"PUT" json:@{@"name":newName, @"id":@(wspace.wspaceId)}];
	NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
	{
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		if (httpResponse.statusCode == 200) {
			Rc2Workspace *modSpace = [[Rc2Workspace alloc] initWithJsonData:json];
			NSMutableArray *spaces = [self.loginSession.workspaces mutableCopy];
			[spaces replaceObjectAtIndex:[spaces indexOfObject:wspace] withObject:modSpace];
			[spaces sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
			self.loginSession.workspaces = spaces;
			dispatchOnMainQueue( ^{handler(YES, modSpace, nil);} );
		} else {
			Rc2LogWarn(@"rename workspace got unknown error:%ld", (long)httpResponse.statusCode);
			dispatchOnMainQueue( ^{handler(NO, nil, error); });
		}
	}];
	[task resume];
}

-(void)deleteWorkspce:(Rc2Workspace*)wspace completionHandler:(Rc2RestCompletionHandler)handler
{
	NSString *path = [NSString stringWithFormat:@"workspaces/%d", wspace.wspaceId];
	NSMutableURLRequest *req = [self requestWithPath:path method:@"DELETE" json:nil];
	NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
	{
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		if (httpResponse.statusCode == 200) {
			NSMutableArray *spaces = [self.loginSession.workspaces mutableCopy];
			[spaces removeObject:wspace];
			self.loginSession.workspaces = spaces;
			dispatchOnMainQueue( ^{handler(YES, nil, nil);} );
		} else {
			Rc2LogWarn(@"delete workspace got unknown error:%ld", (long)httpResponse.statusCode);
			dispatchOnMainQueue( ^{handler(NO, nil, error); });
		}
	}];
	[task resume];
}

@end
