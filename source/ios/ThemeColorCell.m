//
//  ThemeColorCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ThemeColorCell.h"
#import "ThemeColorEntry.h"


@implementation ThemeColorCell

-(void)setColorEntry:(ThemeColorEntry *)colorEntry
{
	self.nameLabel.text = colorEntry.name;
	self.colorView.color = colorEntry.color;
}

@end

@implementation ColorView

-(void)setColor:(UIColor *)color
{
	_color = color;
	self.layer.backgroundColor = [color CGColor];
}

@end