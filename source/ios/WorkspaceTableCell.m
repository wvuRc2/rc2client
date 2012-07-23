//
//  WorkspaceTableCell.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "WorkspaceTableCell.h"
#import "RCWorkspaceItem.h"
#import "ThemeEngine.h"

@interface WorkspaceTableCell() {
	CALayer *_bgLayer;
}
@property (nonatomic, strong) NSArray *normalColors;
@property (nonatomic, strong) NSArray *selectedColors;
@property (nonatomic, strong) CAGradientLayer *gl;
@property (nonatomic, strong) id themeChangeNotice;
-(void)updateForNewTheme:(Theme*)theme;
@end

@implementation WorkspaceTableCell
@synthesize imageView;
@synthesize label;
@synthesize item=_item;
@synthesize drawSelected=_drawSelected;
@synthesize normalColors;
@synthesize selectedColors;
@synthesize gl;
@synthesize themeChangeNotice;

-(void)awakeFromNib
{
	__weak WorkspaceTableCell *blockSelf = self;
	id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *theme) {
		[blockSelf updateForNewTheme:theme];
	}];
	self.themeChangeNotice = tn;
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	self.normalColors = [NSArray arrayWithObjects:
						 (id)[theme colorForKey:@"MasterCellStart"].CGColor,
						 (id)[theme colorForKey:@"MasterCellEnd"].CGColor, nil];
	self.selectedColors = [NSArray arrayWithObjects:
						   (id)[theme colorForKey:@"MasterCellSelectedStart"].CGColor,
						   (id)[theme colorForKey:@"MasterCellSelectedEnd"].CGColor, nil];
	_bgLayer = [CALayer layer];
	_bgLayer.cornerRadius = 13;
	CGRect bgRect = CGRectInset([self frame], 4, 4);
	_bgLayer.frame = bgRect;
    [_bgLayer setPosition:CGPointMake([self bounds].size.width/2, [self bounds].size.height/2)];
    [self.layer setMasksToBounds:YES];
	self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	[self.layer insertSublayer:_bgLayer atIndex:0];

	// Initialize the gradient layer
    self.gl = [CAGradientLayer layer];
    [gl setBounds:bgRect];
    [gl setPosition:CGPointMake([self bounds].size.width/2, [self bounds].size.height/2)];
    [self.layer insertSublayer:gl atIndex:1];
    [[self layer] setCornerRadius:13.0f];
	[gl setColors:self.normalColors];

	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	[self addShineLayer:self.layer bounds:bgRect];
}

-(void)updateForNewTheme:(Theme*)theme
{
	self.normalColors = [NSArray arrayWithObjects:
						 (id)[theme colorForKey:@"MasterCellStart"].CGColor,
						 (id)[theme colorForKey:@"MasterCellEnd"].CGColor, nil];
	self.selectedColors = [NSArray arrayWithObjects:
						   (id)[theme colorForKey:@"MasterCellSelectedStart"].CGColor,
						   (id)[theme colorForKey:@"MasterCellSelectedEnd"].CGColor, nil];
	[gl setColors:self.normalColors];
	if (_drawSelected)
		[gl setColors:self.selectedColors];
	if (self.item) {
		//adjust images
		UIColor *tintColor = [theme colorForKey:@"MasterImageTint"];
		imageView.image = [[UIImage imageNamed: self.item.isFolder ? @"folder" : @"workspace"] imageTintedWithColor:tintColor];
		imageView.highlightedImage = [UIImage imageNamed: self.item.isFolder ? @"folder" : @"workspaceHi"];
	}
	[self setNeedsDisplay];
}

-(void)dealloc
{
	self.item=nil;
}

-(void)setDrawSelected:(BOOL)seld
{
	_drawSelected=seld;
	if (_drawSelected)
		[gl setColors:self.selectedColors];
	else
		[gl setColors:self.normalColors];
}

-(void)setItem:(RCWorkspaceItem *)anItem
{
	_item = anItem;
	label.text = anItem.name;
	
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	UIColor *tintColor = [theme colorForKey:@"MasterImageTint"];
	imageView.image = [[UIImage imageNamed: anItem.isFolder ? @"folder" : @"workspace"] imageTintedWithColor:tintColor];
	imageView.highlightedImage = [UIImage imageNamed: anItem.isFolder ? @"folder" : @"workspaceHi"];
}
@end
