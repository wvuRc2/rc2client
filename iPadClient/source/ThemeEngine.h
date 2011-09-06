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
@end


@interface ThemeEngine : NSObject
+(Theme*)currentTheme;
@end
