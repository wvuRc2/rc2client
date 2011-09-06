//
//  ThemeEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "ThemeEngine.h"

@interface Theme()
@property (nonatomic, copy) NSDictionary *themeDict;
@end

@implementation Theme
@synthesize themeDict;
-(id)init
{
	if ((self = [super init])) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultTheme" ofType:@"plist"];
		ZAssert(path, @"gotta have a theme file");
		self.themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
	}
	return self;
}
-(NSDictionary*)themeColors
{
	return [self.themeDict objectForKey:@"colors"];
}
-(UIColor*)colorForKey:(NSString*)key
{
	return [UIColor colorWithHexString:[self.themeColors objectForKey:key]];
}
@end

@implementation ThemeEngine
+(Theme*)currentTheme
{
	static dispatch_once_t pred;
	static Theme *global;
	
	dispatch_once(&pred, ^{ 
		global = [[Theme alloc] init];
	});
	
	return global;
}
@end
