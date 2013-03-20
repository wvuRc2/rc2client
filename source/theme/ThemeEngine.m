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
#define COLOR_W_WHITE colorWithWhite
#else
#import <Vyana/CALayer+LayerDebugging.h>
#define COLOR_W_WHITE colorWithCalibratedWhite
#endif

#define kPref_CurrentTheme @"CurrentThemeEngineTheme"
#define kPref_CustomThemeData @"CustomThemeData"

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
	if ((self = [super init])) {
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

-(COLOR_CLASS*)colorForKey:(NSString*)key
{
	COLOR_CLASS *color = [_colorCache objectForKey:key];
	if (nil == color) {
		@try {
			color = [COLOR_CLASS colorWithHexString:[self hexStringForKey:key]];
			if (color)
				[_colorCache setObject:color forKey:key];
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
		global = [[ThemeEngine alloc] init];
		NSMutableArray *a = [NSMutableArray array];
		for (NSURL *aUrl in [[NSBundle mainBundle] URLsForResourcesWithExtension:@"plist" subdirectory:@"themes"]) {
			NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL:aUrl];
			if ([[d objectForKey:@"version"] intValue] >= 21) {
				Theme *t = [[Theme alloc] initWithDictionary:d];
				if ([t.name isEqualToString:@"Default"]) {
					global->_currentTheme = t;
					global->_defaultTheme = t;
				}
				[a addObject:t];
			}
		}
		NSString *tname = [[NSUserDefaults standardUserDefaults] stringForKey:kPref_CurrentTheme];
		if (tname) {
			Theme *t = [a firstObjectWithValue:tname forKey:@"name"];
			if (t)
				global.currentTheme = t;
		}
		[global createCustomTheme];
		global->_allThemes = [a copy];
		global->_toNotify = [[NSMutableSet alloc] init];
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
-(NSArray*)allThemes
{
	return _allThemes;
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
			_allThemes = [_allThemes arrayByAddingObject:self.customTheme];
		}
	} else {
		if ([_allThemes containsObject:self.customTheme]) {
			NSUInteger idx = [_allThemes indexOfObject:self.customTheme];
			if (idx != NSNotFound) {
				_allThemes = [_allThemes arrayByRemovingObjectAtIndex:idx];
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
	ThemeNotifyTracker *tn = [[ThemeNotifyTracker alloc] init];
	tn.block = tblock;
	tn.observer = [MAZeroingWeakRef refWithTarget:obs];
	[_toNotify addObject:tn];
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
    CAGradientLayer *gl = [CAGradientLayer layer];
    [gl setBounds:frame];
    [gl setPosition:CGPointMake(parentLayer.bounds.size.width/2, parentLayer.bounds.size.height/2)];
    [parentLayer insertSublayer:gl atIndex:(unsigned)[parentLayer.sublayers count]];
	gl.zPosition = -1;
	gl.name = kThemeBGLayerName;
	//now we need to find out what colors to use
	Theme *th = _currentTheme;
	COLOR_CLASS *startColor = [th colorForKey:[key stringByAppendingString:@"Start"]];
	COLOR_CLASS *endColor = [th colorForKey:[key stringByAppendingString:@"End"]];
	if (startColor && endColor) {
		NSArray *colors = [NSArray arrayWithObjects:(id)startColor.CGColor, (id)endColor.CGColor, nil];
		[gl setColors:colors];
	} else {
		startColor = [th colorForKey:key];
		if (startColor) {
			gl.backgroundColor = startColor.CGColor;
		}
	}
}

-(NSArray*)allColorKeys
{
	if (nil == self.colorKeys) {
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ThemeEngine" ofType:@"plist"]];
		ZAssert(dict, @"failed to load theme engine config");
		self.colorKeys = [dict objectForKey:@"colorKeys"];
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
	NSString *str = [self.themeColors objectForKey:key];
	if (nil == str)
		str = [self.defaultTheme hexStringForKey:key];
	return str;
}

-(NSArray*)colorEntries
{
	if (nil != self.themeColorEntries)
		return [self.themeColorEntries copy];
	NSMutableArray *a = [NSMutableArray array];
	for (NSString *aKey in [[ThemeEngine sharedInstance] allColorKeys]) {
		ThemeColorEntry *entry = [[ThemeColorEntry alloc] initWithName:aKey color:[self colorForKey:aKey]];
		[a addObject:entry];
	}
	self.themeColorEntries = a;
	return [a copy];
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
			[dict setObject:custom forKey:@"colors"];
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
			[cdict setObject:hex forKey:entry.name];
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
                         (id)[COLOR_CLASS COLOR_W_WHITE:0.8f alpha:0.4f].CGColor,
                         (id)[COLOR_CLASS COLOR_W_WHITE:0.8f alpha:0.2f].CGColor,
                         (id)[COLOR_CLASS COLOR_W_WHITE:0.75f alpha:0.2f].CGColor,
                         (id)[COLOR_CLASS COLOR_W_WHITE:0.4f alpha:0.2f].CGColor,
                         (id)[COLOR_CLASS COLOR_W_WHITE:1.0f alpha:0.4f].CGColor,
                         nil];
    shineLayer.locations = @[@0.0f, @0.3f, @0.3f, @0.8f, @1.0f];
    [parentLayer addSublayer:shineLayer];
}
@end
#endif
