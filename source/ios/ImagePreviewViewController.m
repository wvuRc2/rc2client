//
//  ImagePreviewViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

/*
	to present this in the proper way is a nightmare with the custom transition animation. 
	we're doing plenty of frame/bounds work to make sure it is always the same size (it was streching to 200 wide, which made no sense.
	also have to do an orietation hack for upside down portrait.
 */
#import "ImagePreviewViewController.h"
#import "RCImage.h"
#import "MAKVONotificationCenter.h"

#define kViewWidth 440
#define kViewHeight 466
#define kPortraitBottomMargin 20
#define kLandscapeRightMargin 20

@interface ImagePreviewViewController ()
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIButton *detailsButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) UIImageView *animationImage;
@property (nonatomic, strong) id<MAKVOObservation> curImageToken;
@end

@interface ImagePreviewView : UIView
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property BOOL displayed;
-(CGRect)rectForOrientation;
@end

@implementation ImagePreviewViewController

-(instancetype)init
{
	self = [super initWithNibName:@"ImagePreviewViewController" bundle:nil];
	if (self) {
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	self.view.clipsToBounds = YES;

	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
	gesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.view addGestureRecognizer:gesture];
	gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];

	self.animationImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kViewWidth, kViewHeight)];
	
	self.view.backgroundColor = [UIColor darkGrayColor];
	self.nameLabel.textColor = [UIColor whiteColor];
	self.closeButton.tintColor = [UIColor whiteColor];
	self.pageControl.tintColor = [UIColor whiteColor];
	self.detailsButton.tintColor = [UIColor whiteColor];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadCurrentImage];
	UIGraphicsBeginImageContext(self.view.bounds.size);
	[self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	self.animationImage.image = img;
	[self.view addSubview:self.animationImage];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.animationImage removeFromSuperview];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	if (self.dismissalBlock) {
		self.dismissalBlock(self);
		self.dismissalBlock=nil;
	}
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	ImagePreviewView *view = (ImagePreviewView*)self.view;
	view.frame = view.rectForOrientation;
}

-(void)loadCurrentImage
{
	[self.curImageToken remove];
	RCImage *img = self.images[self.currentIndex];
	[UIView transitionWithView:self.imageView duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.imageView.image = img.image;
	} completion:nil];
	self.nameLabel.text = img.name;
	self.pageControl.numberOfPages = self.images.count;
	self.pageControl.currentPage = self.currentIndex;
	self.curImageToken = [self observeTarget:img keyPath:@"image" options:0 block:^(MAKVONotification *notification) {
		[self loadCurrentImage];
	}];
}

-(void)swipeLeft:(UISwipeGestureRecognizer*)gesture
{
	if (self.currentIndex + 1 < self.images.count) {
		self.currentIndex = self.currentIndex + 1;
		[self loadCurrentImage];
	}
}

-(void)swipeRight:(UISwipeGestureRecognizer*)gesture
{
	if (self.currentIndex > 0) {
		self.currentIndex = self.currentIndex - 1;
		[self loadCurrentImage];
	}
}

-(void)presentationComplete
{
	ImagePreviewView *view = (ImagePreviewView*)self.view;
	[view setDisplayed:YES];
	[view setFrame:[view rectForOrientation]];
}

-(IBAction)showDetails:(id)sender
{
	if (self.detailsBlock)
		self.detailsBlock(self);
}

-(IBAction)pageControlTapped:(id)sender
{
	if (self.currentIndex + 1 == self.images.count)
		self.currentIndex = -1; //swipeLeft will increment
	[self swipeLeft:nil];
}

-(IBAction)dismissSelf:(id)sender
{
	if (self.presentingViewController != self)
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(CGRect)targetFrame
{
	CGRect r = [(ImagePreviewView*)self.view rectForOrientation];
	return r;
}

@end

@implementation ImagePreviewView

-(void)layoutSubviews
{
	[super layoutSubviews];
	CGRect r = self.nameLabel.frame;
	CGRect vr = self.bounds;
	r.origin.x = floorf((vr.size.width - r.size.width)/2);
	self.nameLabel.frame = r;
}

-(void)setBounds:(CGRect)bounds
{
	if (self.displayed) {
		bounds.size.width = kViewWidth;
		bounds.size.height = kViewHeight;
	}
	[super setBounds:bounds];
}

-(CGRect)rectForOrientation
{
	BOOL ios7 = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1;
	UIDeviceOrientation curOrientation = [UIDevice currentDevice].orientation;
	CGRect frame = CGRectZero;
	frame.size.width = kViewWidth;
	frame.size.height = kViewHeight;
	if (ios7 && UIInterfaceOrientationIsLandscape(curOrientation)) {
		frame.size.width = kViewHeight;
		frame.size.height = kViewWidth;
	}
	CGSize sz = [[UIScreen mainScreen] bounds].size;
	frame.origin.x = floorf((sz.width - frame.size.width)/2);
	if (UIInterfaceOrientationIsPortrait(curOrientation)) {
		CGFloat py = floorf(sz.height - (frame.size.height + kPortraitBottomMargin));
		if (ios7) {
			if (curOrientation == UIInterfaceOrientationPortraitUpsideDown)
				py = kPortraitBottomMargin;
		}
		frame.origin.y = py;
	} else {
		if (ios7) {
			frame.origin.y = UIInterfaceOrientationLandscapeLeft == curOrientation ?
				kLandscapeRightMargin : floorf(sz.height - frame.size.height - kLandscapeRightMargin);
			frame.origin.x = 184;
		} else {
			frame.origin.x = sz.width - frame.size.width - kLandscapeRightMargin;
			frame.origin.y = 184;
		}
	}
	return frame;
}

-(void)setFrame:(CGRect)frame
{
	if (self.displayed)
		frame = [self rectForOrientation];
	[super setFrame:frame];
}

@end