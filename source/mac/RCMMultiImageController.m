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
@property (nonatomic, weak) IBOutlet NSButton *shareButton;
@property (nonatomic, strong) IBOutlet RCMMultiUpView *mupView;
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

-(BOOL)acceptsFirstResponder { return YES; }

-(void)awakeFromNib
{
	self.imageView1 = [[RCMImageDetailController alloc] init];
	self.imageView2 = [[RCMImageDetailController alloc] init];
	self.imageView3 = [[RCMImageDetailController alloc] init];
	self.imageView4 = [[RCMImageDetailController alloc] init];
	self.mupView.viewControllers = @[self.imageView1, self.imageView2, self.imageView3, self.imageView4];
	[self.shareButton sendActionOn:NSLeftMouseDownMask];
}

-(void)viewDidMoveToWindow
{
	if (nil == self.view.window) {
		[[NSUserDefaults standardUserDefaults] setInteger:self.numberImagesVisible forKey:kPref_NumImagesVisible];
		if (self.didLeaveWindowBlock)
			self.didLeaveWindowBlock();
		//our view is still involved in an animation, so we need to keep a reference around for longer than the animation
		RunAfterDelay(0.5, ^{
			[self.mupView description];
		});
	} else {
		[self.view.window makeFirstResponder:self];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (@selector(adjustVisibleImages:) == menuItem.action) {
		NSInteger mode = menuItem.tag;
		if (mode == 4)
			mode = 3;
		mode--; //make 0, 1, or 2
		if (mode == self.mupView.mode) {
			[menuItem setState:NSOnState];
			return NO;
		} else {
			[menuItem setState:NSOffState];
			return YES;
		}
	}
	return YES;
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

-(IBAction)imageMenuEnabled:(id)sender
{
	
}

-(IBAction)adjustVisibleImages:(id)sender
{
	[self setNumberImagesVisible:[sender tag]];
}

-(IBAction)shareImages:(id)sender
{
	//get images to share
	NSMutableArray *images = [NSMutableArray arrayWithCapacity:4];
	[images addObject:self.imageView1.selectedImage.fileUrl];
	if (self.mupView.mode > MultiUpQuantity_1) {
		[images addObject:self.imageView2.selectedImage.fileUrl];
		if (self.mupView.mode > MultiUpQuantity_2) {
			[images addObject:self.imageView3.selectedImage.fileUrl];
			[images addObject:self.imageView4.selectedImage.fileUrl];
		}
	}
	//remove duplicates
	NSArray *toShare = [[NSSet setWithArray:images] allObjects];
	
	NSSharingServicePicker *picker = [[NSSharingServicePicker alloc] initWithItems:toShare];
	[picker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
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
