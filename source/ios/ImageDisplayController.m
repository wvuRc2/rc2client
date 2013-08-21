//
//  ImageDisplayController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "ImageDisplayController.h"
#import "ImageHolderView.h"
#import "RCImage.h"
#import "ImagePickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#define kLastUpKey @"@WhuuzUp"
#define kAnimDuration 0.5

#define k4upLandImg1Rect CGRectMake(166, 60, 320, 320)
#define k4upLandImg2Rect CGRectMake(514, 60, 320, 320)
#define k4upLandImg3Rect CGRectMake(166, 408, 320, 320)
#define k4upLandImg4Rect CGRectMake(514, 408, 320, 320)

#define k4upPortImg1Rect CGRectMake(50, 168, 320, 320)
#define k4upPortImg2Rect CGRectMake(398, 168, 320, 320)
#define k4upPortImg3Rect CGRectMake(50, 516, 320, 320)
#define k4upPortImg4Rect CGRectMake(398, 516, 320, 320)

#define k2upLandImg1Rect CGRectMake(20, 144, 460, 460)
#define k2upLandImg2Rect CGRectMake(544, 144, 460, 460)

#define k2upPortImg1Rect CGRectMake(154, 48, 460, 460)
#define k2upPortImg2Rect CGRectMake(154, 526, 460, 460)

#define k1upLandImg1Rect CGRectMake(212, 74, 600, 600)

#define k1upPortImg1Rect CGRectMake(84, 193, 600, 600)

@interface ImageDisplayController() {
	UIButton *_actionButton;
}
@property (nonatomic, strong) RCImage *actionImage;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) ImagePickerController *imagePicker;
@property (nonatomic, strong) UIPopoverController *imagePopover;
-(void)layoutAs1Up;
-(void)layoutAs2Up;
-(void)layoutAs4Up;
-(void)adjustLayout;
-(void)adjustFramesFor1Up:(UIInterfaceOrientation)orient;
-(void)adjustFramesFor2Up:(UIInterfaceOrientation)orient;
-(void)adjustFramesFor4Up:(UIInterfaceOrientation)orient;
-(IBAction)doEmail:(id)sender;
-(IBAction)doPhotoLib:(id)sender;
-(IBAction)doPrint:(id)sender;
@end

@implementation ImageDisplayController

- (id)init
{
	return [super initWithNibName:@"ImageDisplayController" bundle:nil];
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
	
	self.whatUp = [[UISegmentedControl alloc] initWithItems:@[@"1",@"2",@"4"]];
	[self.whatUp setWidth:40 forSegmentAtIndex:0];
	[self.whatUp setWidth:40 forSegmentAtIndex:1];
	[self.whatUp setWidth:40 forSegmentAtIndex:2];
	[self.whatUp addTarget:self action:@selector(whatUpDawg:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.rightBarButtonItems = [self.standardRightNavBarItems arrayByAddingObject:[[UIBarButtonItem alloc] initWithCustomView:self.whatUp]];
	if (nil == self.navigationItem.title)
		self.navigationItem.title = @"Image";
	self.navigationItem.leftBarButtonItems = self.standardLeftNavBarItems;

	self.holder1.delegate=self;
	self.holder2.delegate=self;
	self.holder3.delegate=self;
	self.holder4.delegate=self;
	self.whatUp.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kLastUpKey];
	[self adjustLayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[UIView animateWithDuration:duration animations:^{
		switch (self.whatUp.selectedSegmentIndex) {
			case 0:
			default:
				[self adjustFramesFor1Up:toInterfaceOrientation];
				break;
			case 1:
				[self adjustFramesFor2Up:toInterfaceOrientation];
				break;
			case 2:
				[self adjustFramesFor4Up:toInterfaceOrientation];
				break;
		}
	}];
}

-(void)setImageDisplayCount:(NSInteger)imgCount
{
	ZAssert(imgCount > 0, @"invalid image count");
	if (imgCount > 3)
		imgCount = 3; //convert a 4 to a 3
	self.whatUp.selectedSegmentIndex = imgCount-1; //convert to zero-based
	[self adjustLayout];
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
		[self adjustFramesFor1Up:self.interfaceOrientation];
	}];
}

-(void)layoutAs2Up
{
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.holder1.alpha = 1;
		self.holder2.alpha = 1;
		self.holder3.alpha = 0;
		self.holder4.alpha = 0;
		[self adjustFramesFor2Up:self.interfaceOrientation];
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
		[self adjustFramesFor4Up:self.interfaceOrientation];
		self.holder1.scrollView.zoomScale = .5;
		self.holder2.scrollView.zoomScale = .5;
		self.holder3.scrollView.zoomScale = .5;
		self.holder4.scrollView.zoomScale = .5;
	}];
}

-(void)adjustFramesFor1Up:(UIInterfaceOrientation)orient
{
	if (UIInterfaceOrientationIsLandscape(orient)) {
		self.holder1.frame = k1upLandImg1Rect;
	} else {
		self.holder1.frame = k1upPortImg1Rect;
	}
}

-(void)adjustFramesFor2Up:(UIInterfaceOrientation)orient
{
	if (UIInterfaceOrientationIsLandscape(orient)) {
		self.holder1.frame = k2upLandImg1Rect;
		self.holder2.frame = k2upLandImg2Rect;
	} else {
		self.holder1.frame = k2upPortImg1Rect;
		self.holder2.frame = k2upPortImg2Rect;
	}
}

-(void)adjustFramesFor4Up:(UIInterfaceOrientation)orient
{
	if (UIInterfaceOrientationIsLandscape(orient)) {
		self.holder1.frame = k4upLandImg1Rect;
		self.holder2.frame = k4upLandImg2Rect;
		self.holder3.frame = k4upLandImg3Rect;
		self.holder4.frame = k4upLandImg4Rect;
	} else {
		self.holder1.frame = k4upPortImg1Rect;
		self.holder2.frame = k4upPortImg2Rect;
		self.holder3.frame = k4upPortImg3Rect;
		self.holder4.frame = k4upPortImg4Rect;
	}
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
		self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self
											  cancelButtonTitle:nil destructiveButtonTitle:nil
											  otherButtonTitles:@"Email Image", @"Add to Photos", printTitle, nil];
	}
	self.actionImage = img;
	_actionButton=button;
	if ([self.actionSheet isVisible]) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
	} else {
		[self.actionSheet showFromRect:[button frame] inView:[button superview] animated:YES];
	}
}

-(void)showImageSwitcher:(ImageHolderView*)imgView forRect:(CGRect)rect
{
	if (nil == self.imagePicker) {
		self.imagePicker = [[ImagePickerController alloc] init];
		self.imagePopover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
		self.imagePicker.contentSizeForViewInPopover = CGSizeMake(240, 360);
	}
	if (self.imagePopover.isPopoverVisible) {
		[self.imagePopover dismissPopoverAnimated:YES];
		return;
	}
	__weak ImageDisplayController *weakSelf = self;
	self.imagePicker.selectionHandler = ^{
		imgView.image = weakSelf.imagePicker.selectedImage;
		[weakSelf.imagePopover dismissPopoverAnimated:YES];
	};
	self.imagePicker.images = self.allImages;
	self.imagePicker.selectedImage = imgView.image;
	CGRect adjRect = rect;
	adjRect.origin.x = CGRectGetMidX(rect)-1;
	adjRect.size.width = 2;
	[self.imagePopover presentPopoverFromRect:adjRect inView:imgView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	[self.imagePicker.tableView reloadData];
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
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)doPhotoLib:(id)sender
{
	ALAssetsLibrary *photos = [[ALAssetsLibrary alloc] init];
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
									}];
}

-(IBAction)doEmail:(id)sender
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	[picker addAttachmentData:UIImagePNGRepresentation(self.actionImage.image) 
					 mimeType:@"image/png" 
					 fileName:self.actionImage.name];
	[self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)whatUpDawg:(id)sender
{
	[self adjustLayout];
}


@end
