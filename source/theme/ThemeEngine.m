//
//  ThemeEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "MAKVONotificationCenter.h"
#import "ThemeColorEntry.h"

#if TARGET_OS_IPHONE
#import "Vyana-ios/CALayer+LayerDebugging.h"
#else
#import <Vyana/CALayer+LayerDebugging.h>
#endif

NSString *const kPref_CurrentTheme = @"CurrentThemeEngineTheme";
NSString *const kPref_CustomThemeData = @"CustomThemeData";

NSString *const kPrefCustomThemeURL = @"CustomThemeURL";

@interface Theme() {
	@protected
	NSMutableDictionary *_colorCache;
}
@property (nonatomic, strong) NSDictionary *themeDict;
@end

@interface CustomTheme ()
@property (nonatomic, strong) NSMutableArray *themeColorEntries;
-(void)load;
@end

@implementation Theme
@synthesize themeDict;
-(id)initWithDictionary:(NSDictionary*)dict
{
	if (self = [super init]) {
		self.themeDict = dict;
		ZAssert(dict, @"invalid theme info");
		_colorCache = [[NSMutableDictionary alloc] init];
	}
	return self;
}
-(NSString*)name
{
	return [self.themeDict objectForKey:@"name"];
}

-(NSString*)cssfile
{
	return [self.themeDict objectForKey:@"cssfile"];
}

-(NSDictionary*)themeColors
{
	return [self.themeDict objectForKey:@"colors"];
}

-(CGColorRef)cgColorForKey:(NSString*)key
{
	return [self colorForKey:key].CGColor;
}

-(ColorClass*)colorForKey:(NSString*)key
{
	ColorClass *color = [_colorCache objectForKey:key];
	if (nil == color) {
		@try {
			color = [ColorClass colorWithHexString:[self hexStringForKey:key]];
			if (color)
				_colorCache[key] = color;
		} @catch (id e) {
			NSLog(@"error with color '%@' = '%@'", key, [self hexStringForKey:key]);
		}
	}
	return color;
}

//this is laregly for subclasses to override
-(NSString*)hexStringForKey:(NSString*)key
{
	return [self.themeColors objectForKey:key];
}

-(BOOL)isCustom
{
	return NO;
}

-(void)verifyTheme
{
#if DEBUG
	//verify theme
	NSArray *allKeys = [[ThemeEngine sharedInstance] allColorKeys];
	for (NSString *key in [[self.themeDict objectForKey:@"colors"] allKeys]) {
		if (![allKeys containsObject:key])
			Rc2LogWarn(@"theme '%@' has unknown color key '%@'", self.name, key);
	}
#endif
}

@end

@interface ThemeNotifyTracker : NSObject {
}
@property (strong) MAZeroingWeakRef *observer;
@property (copy) ThemeChangedBlock block;
@end

@interface ThemeEngine() {
	NSArray *_allThemes;
	NSMutableSet *_toNotify;
	Theme *_defaultTheme;
}
@property (nonatomic, copy, readwrite) NSArray *allThemes;
-(NSArray*)allColorKeys;
@property (strong, readwrite) CustomTheme *customTheme;
@property (copy) NSArray *colorKeys;
@end

@implementation ThemeEngine
+(ThemeEngine*)sharedInstance
{
	static dispatch_once_t pred;
	static ThemeEngine *global;
	
	dispatch_once(&pred, ^{ 
		NSMutableArray *themes = [NSMutableArray array];
		Theme *defaultTheme = nil;
		for (NSURL *aUrl in [[NSBundle mainBundle] URLsForResourcesWithExtension:@"plist" subdirectory:@"themes"]) {
			NSDictionary *aDict = [NSDictionary dictionaryWithContentsOfURL:aUrl];
			if ([aDict[@"version"] intValue] >= 21) {
				Theme *aTheme = [[Theme alloc] initWithDictionary:aDict];
				if ([aTheme.name isEqualToString:@"Default"]) {
					defaultTheme = aTheme;
				}
				[themes addObject:aTheme];
			}
		}
		global = [[ThemeEngine alloc] initWithDefaultTheme:defaultTheme];
		NSString *tname = [[NSUserDefaults standardUserDefaults] stringForKey:kPref_CurrentTheme];
		if (tname) {
			Theme *theme = [themes firstObjectWithValue:tname forKey:@"name"];
			if (theme)
				global.currentTheme = theme;
		}
		[global createCustomTheme];
		global.allThemes = themes;
		[global observeTarget:[Rc2Server sharedInstance] keyPath:@"loggedIn" options:0 block:^(MAKVONotification *note) {
			[note.observer createCustomTheme];
		}];
		dispatch_async(dispatch_get_main_queue(), ^{
			for (Theme *theme in global.allThemes)
				[theme verifyTheme];
		});
	});
	return global;
}

-(id)initWithDefaultTheme:(Theme*)theme
{
	self = [super init];
	_defaultTheme = theme;
	_currentTheme = theme;
	_toNotify = [[NSMutableSet alloc] init];
	return self;
}

-(void)createCustomTheme
{
	if ([[Rc2Server sharedInstance] isAdmin]) {
		if (nil == self.customTheme) {
			self.customTheme = [[CustomTheme alloc] initWithDictionary:_defaultTheme.themeDict];
			self.customTheme.defaultTheme = _defaultTheme;
			[self.customTheme load];
		}
		if (![_allThemes containsObject:self.customTheme]) {
			self.allThemes = [_allThemes arrayByAddingObject:self.customTheme];
		}
	} else {
		if ([_allThemes containsObject:self.customTheme]) {
			NSUInteger idx = [_allThemes indexOfObject:self.customTheme];
			if (idx != NSNotFound) {
				self.allThemes = [_allThemes arrayByRemovingObjectAtIndex:idx];
				[self setCurrentTheme:_defaultTheme];
			}
		}
	}
}

-(void)setCurrentTheme:(Theme *)newTheme
{
	//only broadcast if actually new. the custom theme can change colors, so we'll rebroadcast it
	if (newTheme == _currentTheme && newTheme != self.customTheme)
		return;
	_currentTheme = newTheme;
	NSMutableSet *oldones = [NSMutableSet set];
	for (ThemeNotifyTracker *tn in _toNotify) {
		if (nil == tn.observer.target) {
			[oldones addObject:tn];
		} else {
			tn.block(newTheme);
		}
	}
	[_toNotify minusSet:oldones];
	[[NSUserDefaults standardUserDefaults] setObject:newTheme.name forKey:kPref_CurrentTheme];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//an object will be returned. releasing that object will unregister the block
-(void)registerThemeChangeObserver:(id)obs block:(ThemeChangedBlock)tblock
{
	ThemeNotifyTracker *tnt = [[ThemeNotifyTracker alloc] init];
	tnt.block = tblock;
	tnt.observer = [MAZeroingWeakRef refWithTarget:obs];
	[_toNotify addObject:tnt];
}

#define kThemeBGLayerName @"themed bg"
//will add a layer that has a gradient background if the current theme has
// the colors for one, otherwise it will use a solid color from the theme.
//if the theme doesn't have that, it will do nothing. the bg will be centered in parentLayer
-(void)addBackgroundLayer:(CALayer*)parentLayer withKey:(NSString*)key frame:(CGRect)frame
{
	CALayer *existingLayer = [parentLayer firstSublayerWithName:kThemeBGLayerName];
	if (nil != existingLayer) {
		[existingLayer removeFromSuperlayer];
	}
    CAGradientLayer *glayer = [CAGradientLayer layer];
    [glayer setBounds:frame];
    [glayer setPosition:CGPointMake(parentLayer.bounds.size.width/2, parentLayer.bounds.size.height/2)];
    [parentLayer insertSublayer:glayer atIndex:(unsigned)[parentLayer.sublayers count]];
	glayer.zPosition = -1;
	glayer.name = kThemeBGLayerName;
	//now we need to find out what colors to use
	Theme *theme = _currentTheme;
	ColorClass *startColor = [theme colorForKey:[key stringByAppendingString:@"Start"]];
	ColorClass *endColor = [theme colorForKey:[key stringByAppendingString:@"End"]];
	if (startColor && endColor) {
		[glayer setColors:@[(id)startColor.CGColor, (id)endColor.CGColor]];
	} else {
		startColor = [theme colorForKey:key];
		if (startColor) {
			glayer.backgroundColor = startColor.CGColor;
		}
	}
}

-(NSArray*)allColorKeys
{
	if (nil == self.colorKeys) {
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ThemeEngine" ofType:@"plist"]];
		ZAssert(dict, @"failed to load theme engine config");
		self.colorKeys = dict[@"colorKeys"];
	}
	return self.colorKeys;
}
@end

@implementation ThemeNotifyTracker
@end


@implementation CustomTheme
-(NSString*)name { return @"Custom"; }
-(BOOL)isCustom { return YES; }

-(NSString*)hexStringForKey:(NSString*)key
{
	NSString *str = self.themeColors[key];
	if (nil == str)
		str = [self.defaultTheme hexStringForKey:key];
	return str;
}

-(NSArray*)colorEntries
{
	if (nil != self.themeColorEntries)
		return [self.themeColorEntries copy];
	NSMutableArray *array = [NSMutableArray array];
	for (NSString *aKey in [[ThemeEngine sharedInstance] allColorKeys]) {
		ThemeColorEntry *entry = [[ThemeColorEntry alloc] initWithName:aKey color:[self colorForKey:aKey]];
		[array addObject:entry];
	}
	self.themeColorEntries = array;
	return [array copy];
}
-(void)load
{
	NSError *err;
	NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kPref_CustomThemeData];
	if (data) {
		NSMutableDictionary *custom = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers
																				 format:nil error:&err];
		if (custom) {
			NSMutableDictionary * dict = [self.themeDict mutableCopy];
			dict[@"colors"] = custom;
			self.themeDict = dict;
		} else {
			Rc2LogWarn(@"failed to parse theme plist:%@", err);
		}
	}
}

-(NSData*)plistContents
{
	NSData *data;
	NSMutableDictionary *cdict = [self.themeDict objectForKey:@"colors"];
	for (ThemeColorEntry *entry in self.colorEntries) {
		NSString *hex = [entry.color hexString];
		if (hex.length > 2)
			cdict[entry.name] = hex;
	}
	NSError *err;
	data = [NSPropertyListSerialization dataWithPropertyList:cdict format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
	if (nil == data) {
		Rc2LogWarn(@"failed to serialize theme as plist:%@", err);
	}
	return data;
}

-(void)save
{
	NSData *data = [self plistContents];
	if (data) {
		[[NSUserDefaults standardUserDefaults] setObject:data forKey:kPref_CustomThemeData];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	//if we are theme, broadcast so UI updates to changes
	if ([[ThemeEngine sharedInstance] currentTheme] == self)
		[[ThemeEngine sharedInstance] setCurrentTheme:self];
}

@end

#if TARGET_OS_IPHONE
@implementation UIView(Shine)
- (void)addShineLayer:(CALayer*)parentLayer bounds:(CGRect)bounds
{
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[ColorClass colorWithWhite:0.8f alpha:0.4f].CGColor,
                         (id)[ColorClass colorWithWhite:0.8f alpha:0.2f].CGColor,
                         (id)[ColorClass colorWithWhite:0.75f alpha:0.2f].CGColor,
                         (id)[ColorClass colorWithWhite:0.4f alpha:0.2f].CGColor,
                         (id)[ColorClass colorWithWhite:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = @[@0.0f, @0.3f, @0.3f, @0.8f, @1.0f];
    [parentLayer addSublayer:shineLayer];
}
@end
#endif
