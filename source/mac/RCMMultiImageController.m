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
#import "RCMMultiUpView.h"

@interface RCMMultiImageController() {
	BOOL _doingResize;
}
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView1;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView2;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView3;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView4;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *layoutControl;
@property (nonatomic, strong) IBOutlet RCMMultiUpView *mupView;
@end

@implementation RCMMultiImageController
@synthesize availableImages=_availableImages;
@synthesize numberImagesVisible=_numberImagesVisible;

- (id)init
{
	if ((self = [super initWithNibName:@"RCMMultiImageController" bundle:nil])) {
		NSInteger numImgs = [[NSUserDefaults standardUserDefaults] integerForKey:kPref_NumImagesVisible];
		NSLog(@"def num imgs:%ld", numImgs);
		self.numberImagesVisible = 1;
	}
	return self;
}

-(BOOL)acceptsFirstResponder { return YES; }

-(void)awakeFromNib
{
	self.imageView1 = [[RCMImageDetailController alloc] init];
	self.imageView2 = [[RCMImageDetailController alloc] init];
	self.imageView3 = [[RCMImageDetailController alloc] init];
	self.imageView4 = [[RCMImageDetailController alloc] init];
	self.mupView.viewControllers = @[self.imageView1, self.imageView2, self.imageView3, self.imageView4];
}

-(void)viewDidMoveToWindow
{
	if (nil == self.view.window) {
		[[NSUserDefaults standardUserDefaults] setInteger:self.numberImagesVisible forKey:kPref_NumImagesVisible];
		if (self.didLeaveWindowBlock)
			self.didLeaveWindowBlock();
	} else {
//		[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[container]-|" options:0 metrics:nil views:@{@"container":self.view}]];
//		[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[container]-|" options:0 metrics:nil views:@{@"container":self.view}]];
		[self.view.window makeFirstResponder:self];
	}
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
	MultiUpMode mode = MultiUpQuantity_1;
	switch (num) {
		case 2:
			mode = MultiUpQuantity_2;
			break;
		case 3:
		case 4:
			mode = MultiUpQuantity_4;
			break;
	}
	[self.mupView setMode:mode];
}
@end
