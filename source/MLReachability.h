/*
	All changes by mlilback are placed in the public domain.
	No rights reserved.
*/

/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE. 
 */

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

extern NSString *const kMLReachabilityChangedNotification;

typedef enum 
{
	// Apple NetworkStatus Compatible Names.
	MLNotReachable     = 0,
	MLReachableViaWWAN = 1,
	MLReachableViaWiFi = 2
} MLNetworkStatus;

@class MLReachability;

typedef void (^MLNetworkReachable)(MLReachability * reachability);
typedef void (^MLNetworkUnreachable)(MLReachability * reachability);

@interface MLReachability : NSObject

@property (nonatomic, copy) MLNetworkReachable reachableBlock;
@property (nonatomic, copy) MLNetworkUnreachable unreachableBlock;


@property (nonatomic, assign) BOOL reachableOnWWAN;

+(MLReachability*)reachabilityWithHostname:(NSString*)hostname;
+(MLReachability*)reachabilityForInternetConnection;
+(MLReachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(MLReachability*)reachabilityForLocalWiFi;

-(MLReachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

-(BOOL)startNotifier;
-(void)stopNotifier;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired; // Identical DDG variant.
-(BOOL)connectionRequired; // Apple's routine.
// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand;
// Is user intervention required?
-(BOOL)isInterventionRequired;

-(MLNetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end