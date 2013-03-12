//
//  NotificationCell.m
//  iPadClient
//
//  Created by Mark Lilback on 5/18/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "NotificationCell.h"
#import "ThemeEngine.h"

@interface NotificationCell() {
	BOOL _didInitialPrepare;
}
@property (nonatomic, strong) CAGradientLayer *gl;
@property (nonatomic, strong) IBOutlet UILabel *typeLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@end

@implementation NotificationCell


-(void)willMoveToWindow:(UIWindow *)newWindow
{
	[super willMoveToWindow:newWindow];
	if (!_didInitialPrepare)
		[self setupUI];
}

-(void)setupUI
{
	// Initialize the gradient layer
    self.gl = [CAGradientLayer layer];
    // Set its bounds to be the same of its parent
	CGRect r = self.bounds;
    [self.gl setBounds:r];
    // Center the layer inside the parent layer
    [self.gl setPosition:CGPointMake(r.size.width/2, r.size.height/2)];
    // Insert the layer at position zero to make sure the text is not obscured
    [[self layer] insertSublayer:self.gl atIndex:0];
	// Set the layer's corner radius
    [[self layer] setCornerRadius:14.0f];
    // Turn on masking
    [[self layer] setMasksToBounds:YES];
	self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

	__weak NotificationCell *blockSelf = self;
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *aTheme) {
		[blockSelf updateForTheme];
	}];
	[self updateForTheme];
	_didInitialPrepare=YES;
}

-(void)updateForTheme
{
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	[self.gl setColors:[NSArray arrayWithObjects:
				   (id)[theme colorForKey:@"NoteCellStart"].CGColor,
				   (id)[theme colorForKey:@"NoteCellEnd"].CGColor, nil]];
}

-(NSString*)stringForType:(NSInteger)noteType
{
	switch (noteType) {
		case 0:
		default:
			return @"New Message";
		case 1:
			return @"Assignment Graded";
	}
}

-(void)setNote:(NSDictionary *)note
{
	_note = note;
	self.typeLabel.text = [self stringForType:[[note objectForKey:@"notetype"] intValue]];
	self.messageLabel.text = [note objectForKey:@"message"];
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[note objectForKey:@"datecreated"] doubleValue] / 1000];
	self.dateLabel.text = [self.dateFormatter stringFromDate:date];
}

@end
