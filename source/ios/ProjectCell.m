//
//  ProjectCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "ProjectCell.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "ThemeEngine.h"

@interface ProjectCell ()
@property (weak) IBOutlet UILabel *nameLabel;
@property (weak) IBOutlet AMLabel *lastAccessLabel;
@property (weak) IBOutlet UIImageView *imageView;
@property (weak) CALayer *cellLayer;
@property (strong) IBOutlet UIView *myView;
@property (strong) AMColor *curColor;
@end

@implementation ProjectCell

-(id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self = [[NSBundle mainBundle] loadNibNamed:@"ProjectCell" owner:nil options:nil].firstObject;
		CALayer *layer = self.layer;
		layer.cornerRadius = 8.0;
		self.backgroundColor = [UIColor clearColor];
		
		layer = [CALayer layer];
		layer.frame = CGRectInset(self.frame, 10, 10);
		layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
		layer.shadowOpacity = 0.8;
		layer.shadowOffset = CGSizeMake(4, -4);
		layer.shadowRadius = 2;
		layer.cornerRadius = 13.0;
		self.curColor = [[AMColor colorWithHexString:@"45a7bc"] colorWithAlpha:0.3];
		layer.backgroundColor = [self.curColor CGColor];
		self.contentView.backgroundColor = [UIColor clearColor];
		[self.contentView.layer addSublayer:layer];
		self.cellLayer = layer;

		__weak ProjectCell *bself = self;
		[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
			[bself adjustColors];
		}];
		self.backgroundView.backgroundColor = [UIColor clearColor];
	}
	return self;
}

-(void)adjustColors
{
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	NSString *colorKey = [self.cellItem isKindOfClass:[RCProject class]] ? ([self.cellItem isClass] ? @"ClassColor" : @"ProjectColor") : @"WorkspaceColor";
	self.curColor = [AMColor colorWithColor:[theme colorForKey: colorKey]];
	self.curColor = [self.curColor colorWithAlpha:0.3];
	self.cellLayer.backgroundColor = [self.curColor CGColor];
}

-(void)setCellItem:(id)cellItem
{
	static NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	});
	
	_cellItem = cellItem;
	self.nameLabel.text = [cellItem name];
	self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	self.lastAccessLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
	self.lastAccessLabel.verticalAlignment =  VerticalAlignmentBottom;
	if ([cellItem isKindOfClass:[RCProject class]]) {
		self.lastAccessLabel.hidden = YES;
	} else {
		self.lastAccessLabel.hidden = NO;
		self.lastAccessLabel.text = [NSString stringWithFormat:@"Last Access:\n%@",[dateFormatter stringFromDate:[cellItem lastAccess]]];
	}
	[self adjustColors];
}

@end
