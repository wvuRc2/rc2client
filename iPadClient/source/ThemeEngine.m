//
//  ThemeEngine.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "ThemeEngine.h"
#import "ASIHTTPRequest.h"
#import "ASICacheDelegate.h"
#import "Vyana-ios/CALayer+LayerDebugging.h"

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
-(void)reloadTheme:(NSData*)data;
@end

@interface ThemeNotifyTracker : NSObject {
}
@property (copy) ThemeChangedBlock block;
@end

@interface ThemeEngine() {
	NSArray *_allThemes;
	NSMutableSet *_toNotify;
	Theme *_defaultTheme;
	NSDictionary *_teDict;
}
@property (nonatomic, retain) ASIHTTPRequest *customRequest;
-(NSArray*)allColorKeys;
@end

@implementation ThemeEngine
@synthesize currentTheme=_currentTheme;
@synthesize customRequest=_customRequest;
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

-(void)startCustomDownload:(CustomTheme*)newTheme
{
	NSString *url = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefCustomThemeURL];
	if (nil == url) {
		self.customRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://loclhoast/index.html"]];
		[self setCurrentTheme:newTheme];
		return;
	}
	self.customRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	self.customRequest.cachePolicy = ASIDoNotReadFromCacheCachePolicy;
	[self.customRequest setCompletionBlock:^{
		[newTheme reloadTheme:self.customRequest.responseData];
		[self setCurrentTheme:newTheme];
	}];
	[self.customRequest startAsynchronous];
}

-(void)setCurrentTheme:(Theme *)newTheme
{
	if (newTheme.isCustom && nil == _customRequest) {
		//we need to fire off a background request
		[self startCustomDownload:(CustomTheme*)newTheme];
		return;
	}
	if (!newTheme.isCustom && newTheme == _currentTheme)
		return;
	_currentTheme = newTheme;
	NSMutableSet *oldones = [NSMutableSet set];
	for (id aWeakRef in _toNotify) {
		ThemeNotifyTracker *tn = [aWeakRef target];
		if (tn)
			tn.block(newTheme);
		else
			[oldones addObject:aWeakRef];
	}
	[_toNotify minusSet:oldones];
	if (newTheme.isCustom)
		self.customRequest=nil;
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

#define kThemeBGLayerName @"themed bg"
//will add a layer that has a gradient background if the current theme has
// the colors for one, otherwise it will use a solid color from the theme.
//if the theme doesn't have that, it will do nothing. the bg will be centered in parentLayer
-(void)addBackgroundLayer:(CALayer*)parentLayer withKey:(NSString*)key frame:(CGRect)frame
{
	if (nil != [parentLayer firstSublayerWithName:kThemeBGLayerName]) {
		NSLog(@"asked to add a bg when already has one");
		return;
	}
    CAGradientLayer *gl = [CAGradientLayer layer];
    [gl setBounds:frame];
    [gl setPosition:CGPointMake(parentLayer.bounds.size.width/2, parentLayer.bounds.size.height/2)];
    [parentLayer insertSublayer:gl atIndex:[parentLayer.sublayers count]];
	gl.zPosition = -1;
	gl.name = kThemeBGLayerName;
	//now we need to find out what colors to use
	Theme *th = _currentTheme;
	UIColor *startColor = [th colorForKey:[key stringByAppendingString:@"Start"]];
	UIColor *endColor = [th colorForKey:[key stringByAppendingString:@"End"]];
	if (startColor && endColor) {
		NSArray *colors = [NSArray arrayWithObjects:(id)startColor.CGColor, (id)endColor.CGColor, nil];
		[gl setColors:colors];
	} else {
		startColor = [th colorForKey:key];
		if (startColor) {
//			gl.backgroundColor = startColor.CGColor;
		}
	}
}

-(void)loadTEDict
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"ThemeEngine" ofType:@"plist"];
	_teDict = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
	ZAssert(_teDict, @"failed to load ThemeEngine.plist");
}

-(NSArray*)allColorKeys
{
	if (nil == _teDict)
		[self loadTEDict];
	return [_teDict objectForKey:@"ColorKeys"];
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
-(void)reloadTheme:(NSData*)data
{
	//setup the base we'll be trying to add to
	NSMutableDictionary *md = [NSMutableDictionary dictionary];
	NSMutableDictionary *mc = [[self.defaultTheme.themeColors mutableCopy] autorelease];
	[md setObject:mc forKey:@"colors"];
	self.themeDict = md;
	if ([_colorCache count] > 40)
		[_colorCache removeAllObjects];
	self.customData = self.defaultTheme.themeDict; //copy defaults to use if we return early
	NSError *err=nil;
	NSDictionary *custDict = [NSPropertyListSerialization propertyListWithData:data 
																		options:NSPropertyListMutableContainers
																		 format:nil error:&err];
	if (nil == custDict) {
		NSLog(@"bad custom theme: %@", [err localizedDescription]);
		return;
	}
	[_colorCache removeAllObjects];
	//if we got here, we think we have a valid dictionary
	//now we need to loop through and add appropriate stuff from secondary
	NSDictionary *custColorDict = [custDict objectForKey:@"colors"];
	for (NSString *aKey in [[ThemeEngine sharedInstance] allColorKeys]) {
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
