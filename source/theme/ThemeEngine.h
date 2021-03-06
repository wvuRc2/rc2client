//
//  ThemeEngine.h
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kPrefCustomThemeURL;

@interface Theme : NSObject
-(CGColorRef)cgColorForKey:(NSString*)key;
-(ColorClass*)colorForKey:(NSString*)key;
-(NSString*)hexStringForKey:(NSString*)key;
-(NSDictionary*)themeColors;
@property (weak, nonatomic, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *cssfile;
@property (nonatomic, readonly) BOOL isCustom;
@end


@interface CustomTheme : Theme
@property (nonatomic, strong) Theme *defaultTheme;
@property (nonatomic, readonly) NSArray *colorEntries; //ColorEntry class
-(NSData*)plistContents;
-(void)save;
@end

//the Theme should not be retained. outside of this block, always ask the ThemeEngine
typedef void (^ThemeChangedBlock)(Theme*);


@interface ThemeEngine : NSObject
@property (nonatomic, strong) Theme *currentTheme;
@property (nonatomic, copy, readonly) NSArray *allThemes;
@property (strong, readonly) NSArray *allColorKeys;
@property (strong, readonly) CustomTheme *customTheme;


+(ThemeEngine*)sharedInstance;
//when owner no longer exists, the block is unregistered
-(void)registerThemeChangeObserver:(id)obs block:(ThemeChangedBlock)tblock;

//will add a layer that has a gradient background if the current theme has
// the colors for one, otherwise it will use a solid color from the theme.
//if the theme doesn't have that, it will do nothing. the bg will be centered in parentLayer
-(void)addBackgroundLayer:(CALayer*)parentLayer withKey:(NSString*)key frame:(CGRect)frame;
@end

#if TARGET_OS_IPHONE
@interface UIView(Shine)
- (void)addShineLayer:(CALayer*)parentLayer bounds:(CGRect)bounds;
@end
#endif
