//
//  ThemeEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "ThemeEngine.h"

@interface Theme() {
	@protected
	NSMutableDictionary *_colorCache;
}
@property (nonatomic, retain) NSDictionary *themeDict;
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
-(BOOL)isCustom
{
	return NO;
}
@end

@interface CustomTheme : Theme
@property (nonatomic, retain) Theme *defaultTheme;
@property (nonatomic, retain) NSDictionary *customData;
-(void)reloadTheme;
@end

@interface ThemeNotifyTracker : NSObject {
}
@property (copy) ThemeChangedBlock block;
@end

@interface ThemeEngine() {
	NSArray *_allThemes;
	NSMutableSet *_toNotify;
	Theme *_defaultTheme;
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
				if ([t.name isEqualToString:@"Default"]) {
					global.currentTheme = t;
					global->_defaultTheme = t;
				}
				[a addObject:t];
				[t release];
			}
		}
		CustomTheme *custom = [[CustomTheme alloc] initWithDictionary:nil];
		[a addObject:custom];
		[custom release];
		custom.defaultTheme = global->_defaultTheme;
		global->_allThemes = [a copy];
		global->_toNotify = [[NSMutableSet alloc] init];
	});
	return global;
}
-(NSArray*)allThemes
{
	return _allThemes;
}

-(void)setCurrentTheme:(Theme *)newTheme
{
	if (!newTheme.isCustom && newTheme == _currentTheme)
		return;
	if (newTheme.isCustom)
		[(CustomTheme*)newTheme reloadTheme];
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

@implementation CustomTheme
@synthesize defaultTheme;
@synthesize customData;
-(NSString*)name { return @"Custom"; }
-(BOOL)isCustom { return YES; }
-(void)reloadTheme
{
	//setup the base we'll be trying to add to
	NSMutableDictionary *md = [NSMutableDictionary dictionary];
	NSMutableDictionary *mc = [[self.defaultTheme.themeColors mutableCopy] autorelease];
	[md setObject:mc forKey:@"colors"];
	self.themeDict = md;
	if ([_colorCache count] > 40)
		[_colorCache removeAllObjects];
	self.customData = self.defaultTheme.themeDict; //copy defaults to use if we return early
	NSString *urlStr = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefCustomThemeURL];
	if (nil == urlStr)
		return;
	NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
	if (nil == data)
		return;
	NSError *err=nil;
	NSDictionary *custDict = [NSPropertyListSerialization propertyListWithData:data 
																		options:NSPropertyListMutableContainers
																		 format:nil error:&err];
	if (nil == custDict) {
		NSLog(@"bad custom theme: %@", [err localizedDescription]);
		return;
	}
	//if we got here, we think we have a valid dictionary
	//now we need to loop through and add appropriate stuff from secondary
	NSDictionary *custColorDict = [custDict objectForKey:@"colors"];
	for (NSString *aKey in [self.defaultTheme.themeColors allKeys]) {
		NSString *val = [custColorDict objectForKey:aKey];
		if (val)
			[mc setObject:val forKey:aKey];
	}
	//if
}
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
