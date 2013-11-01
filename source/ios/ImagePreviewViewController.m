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

#define kViewWidth 416
#define kViewHeight 458
#define kPortraitBottomMargin 20
#define kLandscapeRightMargin 20

@interface ImagePreviewViewController ()
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIToolbar *blurToolbar;
@end

@interface ImagePreviewView : UIView
@property (nonatomic, weak) UIToolbar *blurToolbar;
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
	// Do any additional setup after loading the view from its nib.
	UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
	gesture.direction = UISwipeGestureRecognizerDirectionLeft;
	[self.view addGestureRecognizer:gesture];
	gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	[self.view addGestureRecognizer:gesture];
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	self.blurToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, kViewWidth, kViewHeight)];
	[(ImagePreviewView*)self.view setBlurToolbar:self.blurToolbar];
	[self.blurToolbar setBarTintColor:[[UIColor colorWithHexString:@"#A8A8A8"] colorWithAlphaComponent:0.3]];
	self.view.clipsToBounds = YES;
	[self.view.layer insertSublayer:self.blurToolbar.layer atIndex:0];

	self.nameLabel.backgroundColor = [UIColor greenColor];
	self.imageView.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadCurrentImage];
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
	RCImage *img = self.images[self.currentIndex];
	self.imageView.image = img.image;
	self.nameLabel.text = img.name;
}

-(void)swipeLeft:(UISwipeGestureRecognizer*)gesture
{
	if (self.currentIndex > 0) {
		self.currentIndex = self.currentIndex - 1;
		[self loadCurrentImage];
	}
}

-(void)swipeRight:(UISwipeGestureRecognizer*)gesture
{
	if (self.currentIndex + 1 < self.images.count) {
		self.currentIndex = self.currentIndex + 1;
		[self loadCurrentImage];
	}
}

-(void)presentationComplete
{
	ImagePreviewView *view = (ImagePreviewView*)self.view;
	[view setDisplayed:YES];
	[view setFrame:[view rectForOrientation]];
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
	UIDeviceOrientation curOrientation = [UIDevice currentDevice].orientation;
	CGRect frame = CGRectZero;
	frame.size.width = kViewWidth;
	frame.size.height = kViewHeight;
	if (UIInterfaceOrientationIsLandscape(curOrientation)) {
		frame.size.width = kViewHeight;
		frame.size.height = kViewWidth;
	}
	CGSize sz = [[UIScreen mainScreen] bounds].size;
	frame.origin.x = floorf((sz.width - frame.size.width)/2);
	if (UIInterfaceOrientationIsPortrait(curOrientation)) {
		CGFloat py = floorf(sz.height - (frame.size.height + kPortraitBottomMargin));
		if (curOrientation == UIInterfaceOrientationPortraitUpsideDown)
			py = kPortraitBottomMargin;
		frame.origin.y = py;
	} else {
		frame.origin.y = UIInterfaceOrientationLandscapeLeft == curOrientation ?
			kLandscapeRightMargin : floorf(sz.height - frame.size.height - kLandscapeRightMargin);
		frame.origin.x = 184;
	}
	return frame;
}

-(void)setFrame:(CGRect)frame
{
	if (self.displayed)
		frame = [self rectForOrientation];
	[super setFrame:frame];
	self.blurToolbar.frame = self.bounds;
}

@end