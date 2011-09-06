//
//  ThemeEngine.h
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const ThemeDidChangeNotification;

@interface Theme : NSObject 
-(UIColor*)colorForKey:(NSString*)key;
-(NSDictionary*)themeColors;
@property (nonatomic, readonly) NSString *name;
@end


@interface ThemeEngine : NSObject
@property (retain) Theme *currentTheme;
@property (readonly) NSArray *allThemes;
+(ThemeEngine*)sharedInstance;
@end
