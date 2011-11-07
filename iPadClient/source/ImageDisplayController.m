//
//  ImageDisplayController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "ImageDisplayController.h"
#import "ImageHolderView.h"
#import "RCImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#define kLastUpKey @"@WhuuzUp"
#define kAnimDuration 0.5

@interface ImageDisplayController() {
	CGRect _oframe1, _oframe2, _oframe3, _oframe4;
	UIButton *_actionButton;
}
@property (nonatomic, retain) RCImage *actionImage;
@property (nonatomic, retain) UIActionSheet *actionSheet;
-(void)layoutAs1Up;
-(void)layoutAs2Up;
-(void)layoutAs4Up;
-(void)adjustLayout;
-(IBAction)doEmail:(id)sender;
-(IBAction)doPhotoLib:(id)sender;
-(IBAction)doPrint:(id)sender;
@end

@implementation ImageDisplayController
@synthesize whatUp;
@synthesize holder1;
@synthesize holder2;
@synthesize holder3;
@synthesize holder4;
@synthesize allImages;
@synthesize actionSheet;
@synthesize actionImage;
@synthesize closeHandler;

- (id)init
{
	self = [super initWithNibName:@"ImageDisplayController" bundle:nil];
	if (self) {
		// Custom initialization
	}
	return self;
}

-(void)dealloc
{
	self.holder1=nil;
	self.holder2=nil;
	self.holder3=nil;
	self.holder4=nil;
	self.actionSheet=nil;
	self.actionImage=nil;
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.whatUp.tintColor = [UIColor mauveTaupe];
	self.whatUp.segmentedControlStyle = UISegmentedControlStyleBar;
	CGRect frame = self.whatUp.frame;
	frame.size.height = 36;
	frame.origin.y = 4;
	self.whatUp.frame = frame;

	self.holder1.delegate=self;
	self.holder2.delegate=self;
	self.holder3.delegate=self;
	self.holder4.delegate=self;
	_oframe1 = self.holder1.frame;
	_oframe2 = self.holder2.frame;
	_oframe3 = self.holder3.frame;
	_oframe4 = self.holder4.frame;
	self.whatUp.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kLastUpKey];
	[self adjustLayout];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.actionSheet=nil;
	self.holder1=nil;
	self.holder2=nil;
	self.holder3=nil;
	self.holder4=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
    return UIInterfaceOrientationIsLandscape(ior);
}

-(void)didReceiveMemoryWarning
{
	Rc2LogWarn(@"%@: memory warning", THIS_FILE);
}

-(void)adjustLayout
{
	switch (self.whatUp.selectedSegmentIndex) {
		case 0:
		default:
			[self layoutAs1Up];
			break;
		case 1:
			[self layoutAs2Up];
			break;
		case 2:
			[self layoutAs4Up];
			break;
	}
}

-(void)layoutAs1Up
{
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.holder1.alpha = 1;
		self.holder2.alpha = 0;
		self.holder3.alpha = 0;
		self.holder4.alpha = 0;
		self.holder1.frame = CGRectMake(212, 74, 600, 600);
	}];
}

-(void)layoutAs2Up
{
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.holder1.alpha = 1;
		self.holder2.alpha = 1;
		self.holder3.alpha = 0;
		self.holder4.alpha = 0;
		self.holder1.frame = CGRectMake(20, 144, 460, 460);
		self.holder2.frame = CGRectMake(544, 144, 460, 460);
		self.holder1.scrollView.zoomScale = .75;
		self.holder2.scrollView.zoomScale = .75;
	}];
}

-(void)layoutAs4Up
{
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.holder1.alpha = 1;
		self.holder2.alpha = 1;
		self.holder3.alpha = 1;
		self.holder4.alpha = 1;
		self.holder1.frame = _oframe1;
		self.holder2.frame = _oframe2;
		self.holder3.frame = _oframe3;
		self.holder4.frame = _oframe4;
		self.holder1.scrollView.zoomScale = .5;
		self.holder2.scrollView.zoomScale = .5;
		self.holder3.scrollView.zoomScale = .5;
		self.holder4.scrollView.zoomScale = .5;
	}];
}

-(void)loadImages
{
	if ([self.allImages count] > 3) {
		self.holder4.image = [self.allImages objectAtIndex:3];
		self.holder3.image = [self.allImages objectAtIndex:2];
		self.holder2.image = [self.allImages objectAtIndex:1];
		self.holder1.image = [self.allImages objectAtIndex:0];
	} else if ([self.allImages count] > 2) {
		self.holder4.image = nil;
		self.holder3.image = [self.allImages objectAtIndex:2];
		self.holder2.image = [self.allImages objectAtIndex:1];
		self.holder1.image = [self.allImages objectAtIndex:0];
	} else if ([self.allImages count] > 1) {
		self.holder4.image = nil;
		self.holder3.image = nil;
		self.holder2.image = [self.allImages objectAtIndex:1];
		self.holder1.image = [self.allImages objectAtIndex:0];
	} else if ([self.allImages count] > 0) {
		self.holder4.image = [self.allImages objectAtIndex:0];
		self.holder3.image = [self.allImages objectAtIndex:0];
		self.holder2.image = [self.allImages objectAtIndex:0];
		self.holder1.image = [self.allImages objectAtIndex:0];
	}
}

-(void)loadImage1:(RCImage*)img
{
	self.holder1.image = img;
}

-(void)loadImage:(RCImage*)img
{
	self.holder1.image = img;
	self.holder2.image = img;
	self.holder3.image = img;
	self.holder4.image = img;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch(buttonIndex) {
		case 0:
			[self doEmail:_actionButton];
			break;
		case 1:
			[self doPhotoLib:_actionButton];
			break;
		case 2:
			[self doPrint:_actionButton];
			break;
	}
	_actionButton=nil;
}

-(void)showActionMenuForImage:(RCImage*)img button:(UIButton*)button
{
	if (nil == self.actionSheet) {
		NSString *printTitle = @"Print Image";
		if (![UIPrintInteractionController isPrintingAvailable])
			printTitle=nil;
		self.actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:(id)self
											  cancelButtonTitle:nil destructiveButtonTitle:nil
											  otherButtonTitles:@"Email Image", @"Add to Photos", printTitle, nil] autorelease];
	}
	self.actionImage = img;
	_actionButton=button;
	if ([self.actionSheet isVisible]) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
	} else {
		[self.actionSheet showFromRect:[button frame] inView:[button superview] animated:YES];
	}
}

-(IBAction)doPrint:(id)sender
{
	UIPrintInteractionController *pc = [UIPrintInteractionController sharedPrintController];
	UIPrintInfo *printInfo = [UIPrintInfo printInfo];
	printInfo.outputType = UIPrintInfoOutputGeneral;
	printInfo.jobName = self.actionImage.name;
	pc.printInfo = printInfo;
	pc.printingItem = self.actionImage.image;
	[pc presentFromRect:[sender frame] inView:[sender superview] animated:YES completionHandler:^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
				   if (!completed && error)
					   Rc2LogError(@"print error: %@", [error localizedDescription]);
			   }];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller 
		 didFinishWithResult:(MFMailComposeResult)result 
					   error:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
}

-(IBAction)doPhotoLib:(id)sender
{
	ALAssetsLibrary *photos = [[[ALAssetsLibrary alloc] init] autorelease];
	NSDictionary *mdata = [NSDictionary dictionaryWithObjectsAndKeys:@"Rc2", AVMetadataCommonKeyCreator,
						   @"Rc2 for iPad", AVMetadataCommonKeySoftware,
						   @"©2011 West Virginia University", AVMetadataCommonKeyCopyrights,
						   nil];
	[photos writeImageDataToSavedPhotosAlbum:UIImagePNGRepresentation(self.actionImage.image) 
									metadata:mdata completionBlock:^(NSURL *assetURL, NSError *error) {
										NSString *title = @"Photo Added";
										NSString *msg = @"";
										if (error) {
											title = @"Error Saving Photo";
											msg = [error localizedDescription];
										}
										UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
																						message:msg
																					   delegate:nil
																			  cancelButtonTitle:@"OK"
																			  otherButtonTitles:nil];
										[alert show];
										[alert autorelease];
									}];
}

-(IBAction)doEmail:(id)sender
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	[picker addAttachmentData:UIImagePNGRepresentation(self.actionImage.image) 
					 mimeType:@"image/png" 
					 fileName:self.actionImage.name];
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

-(IBAction)close:(id)sender
{
	self.closeHandler();
}

-(IBAction)whatUpDawg:(id)sender
{
	[self adjustLayout];
}


@end
