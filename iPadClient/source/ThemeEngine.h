//
//  ThemeEngine.h
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Theme : NSObject 
-(UIColor*)colorForKey:(NSString*)key;
-(NSDictionary*)themeColors;
@property (nonatomic, readonly) NSString *name;
@end

typedef void (^ThemeChangedBlock)(Theme*);


@interface ThemeEngine : NSObject
@property (nonatomic, retain) Theme *currentTheme;
@property (readonly) NSArray *allThemes;
+(ThemeEngine*)sharedInstance;
//an object will be returned. releasing that object will unregister the block
-(id)registerThemeChangeBlock:(ThemeChangedBlock)tblock;
@end

@interface UIView(Shine)
- (void)addShineLayer:(CALayer*)parentLayer bounds:(CGRect)bounds;
@end
