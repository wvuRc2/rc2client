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

@implementation RCMMultiImageController
@synthesize availableImages=_availableImages;

- (id)init
{
	if ((self = [super initWithNibName:@"RCMMultiImageController" bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.numberImagesVisible = [[NSUserDefaults standardUserDefaults] integerForKey:kPref_NumImagesVisible];
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.layoutControl 
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

}

-(void)viewDidMoveToWindow
{
	if (nil == self.view.window) {
		[[NSUserDefaults standardUserDefaults] setInteger:self.numberImagesVisible forKey:kPref_NumImagesVisible];
	} else {
		[self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.view
															  attribute:NSLayoutAttributeWidth
															  relatedBy:NSLayoutRelationEqual 
																 toItem:self.view.superview
															  attribute:NSLayoutAttributeWidth
															 multiplier:1.0 
															   constant:0]];
		self.imageView1.view.frame = self.frame1.bounds;
		[self.frame1 addSubview:self.imageView1.view];
		self.imageView2.view.frame = self.frame2.bounds;
		[self.frame2 addSubview:self.imageView2.view];
		self.imageView3.view.frame = self.frame3.bounds;
		[self.frame3 addSubview:self.imageView3.view];
		self.imageView4.view.frame = self.frame4.bounds;
		[self.frame4 addSubview:self.imageView4.view];
	}
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

@synthesize numberImagesVisible;
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
