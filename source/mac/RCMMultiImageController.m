//
//  RCMMultiImageController.m
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMMultiImageController.h"
#import "RCMImageDetailController.h"
#import "RCMImagePrintView.h"
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
}

-(BOOL)acceptsFirstResponder { return YES; }

-(void)viewDidMoveToWindow
{
	if (nil == self.view.window) {
		[[NSUserDefaults standardUserDefaults] setInteger:self.numberImagesVisible forKey:kPref_NumImagesVisible];
		if (self.didLeaveWindowBlock)
			self.didLeaveWindowBlock();
	} else {
		self.imageView1.view.frame = self.frame1.bounds;
		[self.frame1 addSubview:self.imageView1.view];
		self.imageView2.view.frame = self.frame2.bounds;
		[self.frame2 addSubview:self.imageView2.view];
		self.imageView3.view.frame = self.frame3.bounds;
		[self.frame3 addSubview:self.imageView3.view];
		self.imageView4.view.frame = self.frame4.bounds;
		[self.frame4 addSubview:self.imageView4.view];
		[self.view.window makeFirstResponder:self];
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

-(void)print:(id)sender
{
	//figure out which images to print. only what's visible
	NSMutableOrderedSet *a = [[NSMutableOrderedSet alloc] init];
	[a addObject:self.imageView1.selectedImage];
	if (self.numberImagesVisible > 1) {
		[a addObject:self.imageView2.selectedImage];
		if (self.numberImagesVisible > 2) {
			[a addObject:self.imageView3.selectedImage];
			[a addObject:self.imageView4.selectedImage];
		}
	}
	RCMImagePrintView *printView = [[RCMImagePrintView alloc] initWithImages:[a array]];
	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printView];
	printOp.jobTitle = @"Rc2 images";
	[printOp runOperation];
}

#pragma mark - custom resizing

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
	[self.frame3.animator setHidden:YES];
	[self.frame4.animator setHidden:YES];
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

#pragma mark - settors

-(void)setDisplayedImages:(NSArray*)imgs
{
	NSInteger num = 1;
	self.imageView1.selectedImage = [imgs objectAtIndex:0]; //always have at least 1
	if (imgs.count > 1) {
		num = 2;
		self.imageView2.selectedImage = [imgs objectAtIndex:1];
		if (imgs.count > 2) {
			num = 4;
			self.imageView3.selectedImage = [imgs objectAtIndex:2];
			if (imgs.count > 3)
				self.imageView4.selectedImage = [imgs objectAtIndex:3];
		}
	}
	self.numberImagesVisible = num;
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
	//not sure why, but when displaying 2up sometimes the second is hidden. this hack fixes that problem.
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		[self.frame2 setHidden:_numberImagesVisible < 2];
		[self.frame3 setHidden:_numberImagesVisible < 4];
		[self.frame4 setHidden:_numberImagesVisible < 4];
	}];
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
