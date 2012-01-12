//
//  RCSavedSession.m
//  Rc2
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "RCSavedSession.h"

@interface RCSavedSession()
@property (nonatomic, strong) NSMutableDictionary *attrCache;
@end

@implementation RCSavedSession

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


-(NSArray*)commandHistory
{
	NSData *data = self.cmdHistoryData;
	if (data.length < 10)
		return nil;
	return [NSPropertyListSerialization propertyListWithData:data
													 options:NSPropertyListImmutable 
													  format:nil 
													   error:nil];
}

-(void)setCommandHistory:(NSArray *)history
{
	NSError *err=nil;
	self.cmdHistoryData = [NSPropertyListSerialization dataWithPropertyList:history format:NSPropertyListBinaryFormat_v1_0 
																	 options:0 error:&err];
	if (err)
		NSLog(@"got error saving converting cmd history to plist: %@", err);
}

@synthesize attrCache;
@end
