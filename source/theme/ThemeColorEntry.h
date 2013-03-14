//
//  ThemeColorEntry.h
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThemeColorEntry : NSObject
@property (copy) NSString *name;
@property (strong) id color; //UIColor or NSColor
@property (readonly) id originalColor;

-(id)initWithName:(NSString*)name color:(id)color;
@end
