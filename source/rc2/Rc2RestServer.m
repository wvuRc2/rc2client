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
	NSURL *loginUrl = [NSURL URLWithString:@"login" relativeToURL:self.baseUrl];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:loginUrl];
	req.HTTPMethod = @"POST";
	req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"login":login, @"password":password} options:0 error:nil];
	[req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
@end
