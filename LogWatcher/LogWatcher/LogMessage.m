//
//  LogMessage.m
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "LogMessage.h"

@interface LogMessage()
@property (nonatomic, strong) NSDictionary *jsonData;
@end

@implementation LogMessage
-(id)initWithDictionary:(NSDictionary*)dict
{
	self = [super init];
	NSMutableDictionary *md = [dict mutableCopy];
	NSTimeInterval secs = [[dict objectForKey:@"date"] doubleValue];
	[md setObject:[NSDate dateWithTimeIntervalSince1970:secs] forKey:@"date"];
	self.jsonData = md;
	return self;
}

-(NSString*)client
{
	return [self.jsonData objectForKey:@"client"];
}

-(NSNumber*)level
{
	return [self.jsonData objectForKey:@"level"];
}

-(NSNumber*)context
{
	return [self.jsonData objectForKey:@"context"];
}

-(NSString*)version
{
	return [self.jsonData objectForKey:@"client"];
}

-(NSString*)message
{
	return [self.jsonData objectForKey:@"message"];
}

-(NSDate*)date
{
	return [self.jsonData objectForKey:@"date"];
}

@synthesize jsonData;
@end
