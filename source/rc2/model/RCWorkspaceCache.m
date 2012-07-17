//
//  RCWorkspaceCache.m
//
//  Created by Mark Lilback on 12/12/11.
//  Copyright (c) 2011 . All rights reserved.
//

#import "RCWorkspaceCache.h"

@interface RCWorkspaceCache()
@property (nonatomic, strong) NSMutableDictionary *attrCache;
@end

@implementation RCWorkspaceCache

-(NSMutableDictionary*)properties
{
	if (nil == self.attrCache) {
		NSData *data = self.localAttributes;
		if (data) {
			//read from plist
			self.attrCache = [NSPropertyListSerialization propertyListWithData:data
																	   options:NSPropertyListMutableContainers 
																		format:nil 
																		 error:nil];
		}
		if (nil == self.attrCache)
			self.attrCache = [NSMutableDictionary dictionary];
	}
	return self.attrCache;
}

-(void)setProperties:(NSMutableDictionary *)attrs
{
	self.attrCache = [attrs mutableCopy];
	self.localAttributes = [NSPropertyListSerialization dataWithPropertyList:attrs format:NSPropertyListXMLFormat_v1_0 
																	 options:0 error:nil];
}

-(id)propertyForKey:(NSString*)key
{
	return [self.properties objectForKey:key];
}

-(void)setProperty:(id)value forKey:(NSString*)key
{
	NSMutableDictionary *dict = self.properties;
	if (value)
		[dict setObject:value forKey:key];
	else
		[dict removeObjectForKey:key];
	self.properties = dict;
}

-(BOOL)boolPropertyForKey:(NSString*)key
{
	return [[self.properties objectForKey:key] boolValue];
}

-(void)setBoolProperty:(BOOL)val forKey:(NSString*)key
{
	[self setProperty:[NSNumber numberWithBool:val] forKey:key];
}

@synthesize attrCache;
@end
