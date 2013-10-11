//
//  ImagePreviewViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ImagePreviewViewController.h"
#import "RCImage.h"

@interface ImagePreviewViewController ()
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
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
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadCurrentImage];
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

-(IBAction)dismissSelf:(id)sender
{
	if (self.presentingViewController != self)
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
