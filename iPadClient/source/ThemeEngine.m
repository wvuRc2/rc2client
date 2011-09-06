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

@interface ThemeNotifyTracker : NSObject {
}
@property (copy) ThemeChangedBlock block;
@end

@interface ThemeEngine() {
	NSArray *_allThemes;
	NSMutableSet *_toNotify;
}
@end

@implementation ThemeEngine
@synthesize currentTheme=_currentTheme;
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
			global->_toNotify = [[NSMutableSet alloc] init];
		}
	});
	return global;
}
-(NSArray*)allThemes
{
	return _allThemes;
}

-(void)setCurrentTheme:(Theme *)newTheme
{
	if (newTheme == _currentTheme)
		return;
	_currentTheme = newTheme;
	for (id aWeakRef in _toNotify) {
		ThemeNotifyTracker *tn = [aWeakRef target];
		if (tn)
			tn.block(newTheme);
	}
}

//an object will be returned. releasing that object will unregister the block
-(id)registerThemeChangeBlock:(ThemeChangedBlock)tblock
{
	ThemeNotifyTracker *tn = [[ThemeNotifyTracker alloc] init];
	tn.block = tblock;
	AMZeroingWeakRef *weakRef = [AMZeroingWeakRef refWithTarget:tn];
	[_toNotify addObject:weakRef];
	return tn;
}

@end

@implementation ThemeNotifyTracker
@synthesize block;
@end


@implementation UIView(Shine)
- (void)addShineLayer:(CALayer*)parentLayer bounds:(CGRect)bounds
{
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithWhite:0.8f alpha:0.4f].CGColor,
                         (id)[UIColor colorWithWhite:0.8f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.3f],
                            [NSNumber numberWithFloat:0.3f],
                            [NSNumber numberWithFloat:0.8f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [parentLayer addSublayer:shineLayer];
}
@end
