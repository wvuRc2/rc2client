//
//  RCMMultiImageController.m
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMMultiImageController.h"
#import "RCMImageDetailController.h"
#import "RCMAppConstants.h"
#import "RCImage.h"

@interface RCMMultiImageController() {
	BOOL _doingResize;
}
-(void)layoutSubviews;
-(void)layout1up;
-(void)layout2up;
-(void)layout4up;
@end

@implementation RCMMultiImageController
@synthesize availableImages=_availableImages;
@synthesize numberImagesVisible=_numberImagesVisible;

- (id)init
{
	if ((self = [super initWithNibName:@"RCMMultiImageController" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.numberImagesVisible = [[NSUserDefaults standardUserDefaults] integerForKey:kPref_NumImagesVisible];
/*	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.layoutControl 
														  attribute:NSLayoutAttributeCenterX
														  relatedBy:NSLayoutRelationEqual 
															 toItem:self.view
														  attribute:NSLayoutAttributeCenterX
														 multiplier:1.0 
														   constant:0]];

	NSDictionary *objDict = [NSDictionary dictionaryWithObjectsAndKeys:self.frame1, @"frame1", self.frame2, @"frame2",
							 self.frame3, @"frame3", self.frame4, @"frame4", nil];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[frame1(>=100)]-[frame2(==frame1)]-|" options:0 metrics:nil views:objDict]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[frame3(>=100)]-[frame4(==frame3)]-|" options:0 metrics:nil views:objDict]];
*/
	self.view.wantsLayer = YES;
	self.view.layer.borderColor = [NSColor redColor].cgColorRef;
	self.view.layer.borderWidth = 1.0;
	self.numberImagesVisible = 4;
}

-(void)viewDidMoveToWindow
{
	if (nil == self.view.window) {
		[[NSUserDefaults standardUserDefaults] setInteger:self.numberImagesVisible forKey:kPref_NumImagesVisible];
	} else {
/*		[self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.view
															  attribute:NSLayoutAttributeWidth
															  relatedBy:NSLayoutRelationEqual 
																 toItem:self.view.superview
															  attribute:NSLayoutAttributeWidth
															 multiplier:1.0 
															   constant:0]];
*/		self.imageView1.view.frame = self.frame1.bounds;
		[self.frame1 addSubview:self.imageView1.view];
		self.imageView2.view.frame = self.frame2.bounds;
		[self.frame2 addSubview:self.imageView2.view];
		self.imageView3.view.frame = self.frame3.bounds;
		[self.frame3 addSubview:self.imageView3.view];
		self.imageView4.view.frame = self.frame4.bounds;
		[self.frame4 addSubview:self.imageView4.view];
		self.numberImagesVisible = 4;
	}
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	NSRect myBounds = self.view.bounds;
	//center rect
	NSRect r = self.layoutControl.frame;
	r.origin.x = NSMidX(myBounds) - (NSWidth(r) / 2.0);
	self.layoutControl.frame = r;
	_doingResize = YES;
	[self layoutSubviews];
	_doingResize = NO;
}

-(void)layoutSubviews
{
	if (self.numberImagesVisible == 4)
		[self layout4up];
	else if (self.numberImagesVisible == 2)
		[self layout2up];
	else
		[self layout1up];
}

-(void)resizeFrames:(NSRect)f1 frame2:(NSRect)f2 frame3:(NSRect)f3 frame4:(NSRect)f4
{
	if (_doingResize) {
		self.frame1.frame = f1;
		self.frame2.frame = f2;
		self.frame3.frame = f3;
		self.frame4.frame = f4;
	} else {
		[self.frame1.animator setFrame:f1];
		[self.frame2.animator setFrame:f2];
		[self.frame3.animator setFrame:f3];
		[self.frame4.animator setFrame:f4];
	}
}

-(void)layout1up
{
	NSRect myBounds = self.view.bounds;
	CGFloat centerX = floor(NSWidth(myBounds) / 2);
	CGFloat centerY = floor((NSMinY(self.layoutControl.frame) - 8) / 2);
	NSSize boxSize = NSMakeSize(NSWidth(myBounds) - 40, NSMinY(self.layoutControl.frame) - 8 - 20);
	boxSize.width = fmin(boxSize.width, boxSize.height);
	boxSize.height = boxSize.width;
	NSRect f1 = NSMakeRect(centerX - (boxSize.width/2), centerY - (boxSize.height/2), boxSize.width, boxSize.width);
	[self resizeFrames:f1 frame2:f1 frame3:f1 frame4:f1];
}

-(void)layout2up
{
	NSRect myBounds = self.view.bounds;
	CGFloat centerX = floor(NSWidth(myBounds) / 2);
	CGFloat centerY = floor((NSMinY(self.layoutControl.frame) - 8) / 2);
	NSSize boxSize = NSMakeSize((NSWidth(myBounds) - 60) / 2.0, NSMinY(self.layoutControl.frame) - 8 - 20);
	boxSize.width = fmin(boxSize.width, boxSize.height);
	boxSize.height = boxSize.width;
	NSRect f1 = NSMakeRect(centerX - boxSize.width - 10, centerY - (boxSize.height/2), boxSize.width, boxSize.width);
	NSRect f2 = NSMakeRect(NSMaxX(f1) + 20, f1.origin.y, boxSize.width, boxSize.width);
	[self resizeFrames:f1 frame2:f2 frame3:f1 frame4:f2];	
}

-(void)layout4up
{
	NSRect myBounds = self.view.bounds;
	CGFloat centerX = floor(NSWidth(myBounds) / 2);
	NSSize boxSize = NSMakeSize((NSWidth(myBounds) - 60) / 2.0, (NSMinY(self.layoutControl.frame) - 8 - 40) / 2.0);
	boxSize.width = fmin(boxSize.width, boxSize.height);
	boxSize.height = boxSize.width;
	CGFloat startX = centerX - boxSize.width - 30;
	NSRect f3 = NSMakeRect(startX, 20, boxSize.width, boxSize.height);
	NSRect f4 = NSMakeRect(NSMaxX(f3) + 20, 20, boxSize.width, boxSize.height);
	NSRect f1 = NSMakeRect(startX, NSMaxY(f3) + 20, boxSize.width, boxSize.height);
	NSRect f2 = NSMakeRect(f4.origin.x, f1.origin.y, boxSize.width, boxSize.height);
	[self resizeFrames:f1 frame2:f2 frame3:f3 frame4:f4];
}

-(void)setAvailableImages:(NSArray *)imgs
{
	_availableImages = imgs;
	self.imageView1.availableImages = imgs;
	self.imageView2.availableImages = imgs;
	self.imageView3.availableImages = imgs;
	self.imageView4.availableImages = imgs;
	RCImage *img = imgs.firstObject;
	self.imageView1.selectedImage = img;
	self.imageView2.selectedImage = img;
	self.imageView3.selectedImage = img;
	self.imageView4.selectedImage = img;
}

-(void)setNumberImagesVisible:(NSInteger)num
{
	_numberImagesVisible = num;
	[NSAnimationContext beginGrouping];
	[self layoutSubviews];
	[self.frame2.animator setHidden:num < 2];
	[self.frame3.animator setHidden:num < 4];
	[self.frame4.animator setHidden:num < 4];
	[NSAnimationContext endGrouping];
}

@synthesize imageView1;
@synthesize imageView2;
@synthesize imageView3;
@synthesize imageView4;
@synthesize frame1;
@synthesize frame2;
@synthesize frame3;
@synthesize frame4;
@synthesize layoutControl;
@end
