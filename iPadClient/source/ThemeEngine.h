//
//  ThemeEngine.h
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPrefCustomThemeURL @"CustomThemeURL"

@interface Theme : NSObject 
-(UIColor*)colorForKey:(NSString*)key;
-(NSDictionary*)themeColors;
-(NSString*)consoleValueForKey:(NSString*)key;
@property (weak, nonatomic, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *cssfile;
@property (nonatomic, readonly) BOOL isCustom;
@end

typedef void (^ThemeChangedBlock)(Theme*);


@interface ThemeEngine : NSObject
@property (nonatomic, strong) Theme *currentTheme;
@property (weak, readonly) NSArray *allThemes;
+(ThemeEngine*)sharedInstance;
//an object will be returned. releasing that object will unregister the block
-(id)registerThemeChangeBlock:(ThemeChangedBlock)tblock;

//will add a layer that has a gradient background if the current theme has
// the colors for one, otherwise it will use a solid color from the theme.
//if the theme doesn't have that, it will do nothing. the bg will be centered in parentLayer
-(void)addBackgroundLayer:(CALayer*)parentLayer withKey:(NSString*)key frame:(CGRect)frame;
@end

@interface UIView(Shine)
- (void)addShineLayer:(CALayer*)parentLayer bounds:(CGRect)bounds;
@end
