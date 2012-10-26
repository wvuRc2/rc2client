//
//  ProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "ProjectViewController.h"
#import "ProjectCell.h"
#import "Rc2Server.h"

@interface ProjectViewController () <UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak) IBOutlet UICollectionView *collectionView;
@property (strong) NSMutableArray *currentItems;
@end

@implementation ProjectViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	if (![Rc2Server sharedInstance].loggedIn) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged) name:NotificationsReceivedNotification object:nil];
	}
	self.currentItems = [[[Rc2Server sharedInstance] projects] mutableCopy];
	NSLog(@"got %d items", self.currentItems.count);
	UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
	[flow setItemSize:CGSizeMake(200, 150)];
	[flow setScrollDirection:UICollectionViewScrollDirectionVertical];
	self.collectionView.collectionViewLayout = flow;
	self.collectionView.allowsSelection = YES;
	[self.collectionView registerClass:[ProjectCell class] forCellWithReuseIdentifier:@"project"];
	[self.collectionView reloadData];
}

-(void)loginStatusChanged
{
	self.currentItems = [[[Rc2Server sharedInstance] projects] mutableCopy];
	NSLog(@"note %d items", self.currentItems.count);
	[self.collectionView reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.currentItems.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ProjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"project" forIndexPath:indexPath];
	cell.project = [self.currentItems objectAtIndex:indexPath.row];
	return cell;
	
}

@end
