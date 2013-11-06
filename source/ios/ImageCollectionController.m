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

@interface ImageCollectionController () <UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *qtyControl;
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
	self.qtyControl.segmentedControlStyle = UISegmentedControlStyleBar;
	[self.qtyControl setWidth:40 forSegmentAtIndex:0];
	[self.qtyControl setWidth:40 forSegmentAtIndex:1];
	[self.qtyControl setWidth:40 forSegmentAtIndex:2];
	[self.qtyControl addTarget:self action:@selector(qtyChange:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.rightBarButtonItems = [self.standardRightNavBarItems arrayByAddingObject:[[UIBarButtonItem alloc] initWithCustomView:self.qtyControl]];
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
	return self.images.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ImageCollectionCell *cell = (ImageCollectionCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kImageCell forIndexPath:indexPath];
	cell.image = self.images[indexPath.row];
	return cell;
}

@end
