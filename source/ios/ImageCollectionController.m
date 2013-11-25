//
//  ImageCollectionController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/2/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "ImageCollectionController.h"
#import "ImageCollectionCell.h"
#import "ImageCollectionLayout.h"
#import "ImagePickerController.h"
#import "WHMailActivity.h"
#import "WHMailActivityItem.h"
#import "RCImage.h"

@interface ImageCollectionController () <UICollectionViewDataSource,ImageCollectionCellDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *qtyControl;
@property (nonatomic, strong) UIPopoverController *cellPopoverController;
@property (nonatomic, strong) ImagePickerController *imagePicker;
@end

#define kImageCell @"ImageCollectionCell"

@implementation ImageCollectionController

-(ImageCollectionLayout*)imageLayout { return (ImageCollectionLayout*)self.collectionView.collectionViewLayout; }

-(void)loadView
{
	ImageCollectionLayout *layout = [[ImageCollectionLayout alloc] init];
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768) collectionViewLayout:layout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.view = _collectionView;
	_collectionView.dataSource = self;
	UINib *cellNib = [UINib nibWithNibName:@"ImageCollectionCell" bundle:nil];
	[_collectionView registerNib:cellNib forCellWithReuseIdentifier:kImageCell];
	_collectionView.backgroundColor = [UIColor whiteColor];
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	self.qtyControl = [[UISegmentedControl alloc] initWithItems:@[@"1",@"2",@"4"]];
	self.qtyControl.selectedSegmentIndex = 1;
	if (self.images.count < 2) {
		self.qtyControl.selectedSegmentIndex = 0;
		[self imageLayout].visibleCellCount = 1;
		[self.collectionView reloadData];
	}
	[self.qtyControl setWidth:40 forSegmentAtIndex:0];
	[self.qtyControl setWidth:40 forSegmentAtIndex:1];
	[self.qtyControl setWidth:40 forSegmentAtIndex:2];
	[self.qtyControl addTarget:self action:@selector(qtyChange:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareImages:)];
	NSMutableArray *ritems = [self.standardRightNavBarItems mutableCopy];
	[ritems addObject:[[UIBarButtonItem alloc] initWithCustomView:self.qtyControl]];
	[ritems addObject:shareItem];
	self.navigationItem.rightBarButtonItems = ritems;
	if (nil == self.navigationItem.title)
		self.navigationItem.title = @"Image";
	self.navigationItem.leftBarButtonItems = self.standardLeftNavBarItems;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	UIView *sv = self.view.superview;
	UIView *cv = _collectionView;
	NSDictionary *views = NSDictionaryOfVariableBindings(cv);
	[sv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cv]|" options:0 metrics:nil views:views]];
	[sv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cv]|" options:0 metrics:nil views:views]];
	[self.view layoutSubviews];
}

-(void)prepareShareImagePopoverForImages:(NSArray*)images
{
	if (self.cellPopoverController.isPopoverVisible) {
		[self.cellPopoverController dismissPopoverAnimated:YES];
		self.cellPopoverController = nil;
		return;
	}
	NSArray *excluded = @[UIActivityTypeMail,UIActivityTypeAssignToContact,UIActivityTypeMessage,UIActivityTypePostToFacebook,UIActivityTypePostToWeibo];
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray *activs = [NSMutableArray arrayWithCapacity:5];
	[items addObject:[WHMailActivityItem mailActivityItemWithSelectionHandler:^(MFMailComposeViewController *messageC) {
		[messageC setSubject:@"images from Rc²"];
		for (RCImage *image in images) {
			[messageC addAttachmentData:[NSData dataWithContentsOfURL:image.fileUrl] mimeType:@"image/png" fileName:image.fileUrl.lastPathComponent];
		}
	}]];
	for (RCImage *image in images)
		[items addObject:image.image];
	[activs addObject:[[WHMailActivity alloc] init]];
	UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:activs];
	__weak UIActivityViewController *weakAvc = avc;
	avc.excludedActivityTypes = excluded;
	UIPopoverController *pop = [[UIPopoverController alloc] initWithContentViewController:avc];
	avc.completionHandler = ^(NSString *actType, BOOL completed) {
		weakAvc.completionHandler=nil;
		[self.cellPopoverController dismissPopoverAnimated:YES];
		self.cellPopoverController=nil;
	};
	self.cellPopoverController = pop;
}

-(void)imageCollectionCell:(ImageCollectionCell*)cell showActionsFromRect:(CGRect)touchRect
{
	[self prepareShareImagePopoverForImages:@[cell.image]];
	[self.cellPopoverController presentPopoverFromRect:touchRect inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)imageCollectionCell:(ImageCollectionCell*)cell selectImageFrom:(CGRect)rect
{
	if (self.cellPopoverController.isPopoverVisible) {
		[self.cellPopoverController dismissPopoverAnimated:YES];
		self.cellPopoverController = nil;
		return;
	}
	__weak ImageCollectionController *bself = self;
	if (nil == self.imagePicker)
		self.imagePicker = [[ImagePickerController alloc] init];
	self.imagePicker.images = self.images;
	self.imagePicker.selectedImage = cell.image;
	self.imagePicker.selectionHandler = ^{
		cell.image = bself.imagePicker.selectedImage;
		[bself.cellPopoverController dismissPopoverAnimated:YES];
		bself.cellPopoverController = nil;
	};
	self.cellPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
	[self.cellPopoverController presentPopoverFromRect:rect inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)shareImages:(id)sender
{
	[self prepareShareImagePopoverForImages:self.images];
	[self.cellPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)rotation:(NSNotification*)note
{
//	[self.collectionView setCollectionViewLayout:[[ImageCollectionLayout alloc] init] animated:YES];
}

-(void)qtyChange:(id)sender
{
	NSInteger qty=1;
	switch (self.qtyControl.selectedSegmentIndex) {
		case 0:
		case 1:
			qty = self.qtyControl.selectedSegmentIndex + 1;
			break;
		case 2:
			qty = 4;
			break;
	}
	self.imageLayout.visibleCellCount = qty;
	[self.imageLayout invalidateLayout];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return MAX(self.images.count, 4);
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ImageCollectionCell *cell = (ImageCollectionCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kImageCell forIndexPath:indexPath];
	cell.imageDelegate = self;
	if (indexPath.row < self.images.count)
		cell.image = self.images[indexPath.row];
	return cell;
}

@end
