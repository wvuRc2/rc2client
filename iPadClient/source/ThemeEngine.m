//
//  ThemeEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "ThemeEngine.h"

NSString * const ThemeDidChangeNotification = @"ThemeDidChangeNotification";

@interface Theme() {
	NSMutableDictionary *_colorCache;
}
@property (nonatomic, copy) NSDictionary *themeDict;
@end

@implementation Theme
@synthesize themeDict;
-(id)initWithDictionary:(NSDictionary*)dict
{
	if ((self = [super init])) {
		self.themeDict = dict;
		_colorCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}
-(NSString*)name
{
	return [self.themeDict objectForKey:@"name"];
}
-(NSDictionary*)themeColors
{
	return [self.themeDict objectForKey:@"colors"];
}
-(UIColor*)colorForKey:(NSString*)key
{
	UIColor *color = [_colorCache objectForKey:key];
	if (nil == color) {
		color = [UIColor colorWithHexString:[self.themeColors objectForKey:key]];
		if (color)
			[_colorCache setObject:color forKey:key];
	}
	return color;
}
@end

@interface ThemeEngine() {
	NSArray *_allThemes;
}
@end

@implementation ThemeEngine
@synthesize currentTheme;
+(ThemeEngine*)sharedInstance
{
	static dispatch_once_t pred;
	static ThemeEngine *global;
	
	dispatch_once(&pred, ^{ 
		global = [[ThemeEngine alloc] init];
		NSMutableArray *a = [NSMutableArray array];
		for (NSURL *aUrl in [[NSBundle mainBundle] URLsForResourcesWithExtension:@"plist" subdirectory:@"themes"]) {
			NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL:aUrl];
			if ([[d objectForKey:@"version"] intValue] == 21) {
				Theme *t = [[Theme alloc] initWithDictionary:d];
				if ([t.name isEqualToString:@"Default"])
					global.currentTheme = t;
				[a addObject:t];
				[t release];
			}
			global->_allThemes = [a copy];
		}
	});
	return global;
}
-(NSArray*)allThemes
{
	return _allThemes;
}
@end
