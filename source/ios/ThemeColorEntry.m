//
//  ThemeColorEntry.m
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "ThemeColorEntry.h"

@interface ThemeColorEntry ()
@property (readwrite) id originalColor;
@end

@implementation ThemeColorEntry
-(id)initWithName:(NSString*)name color:(id)color
{
	self = [super init];
	_name = name;
	self.color = color;
	self.originalColor = color;
	return self;
}
@end
