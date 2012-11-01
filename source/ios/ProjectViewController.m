//
//  ProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ProjectViewController.h"
#import "ProjectCell.h"
#import "Rc2Server.h"
#import "ThemeEngine.h"
#import "ProjectViewLayout.h"

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
	ProjectViewLayout *flow = [[ProjectViewLayout alloc] init];
	[flow setItemSize:CGSizeMake(200, 150)];
	[flow setScrollDirection:UICollectionViewScrollDirectionVertical];
	self.collectionView.collectionViewLayout = flow;
	self.collectionView.allowsSelection = YES;
	[self.collectionView registerClass:[ProjectCell class] forCellWithReuseIdentifier:@"project"];
	[self.collectionView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}

-(void)loginStatusChanged
{
	self.currentItems = [[[Rc2Server sharedInstance] projects] mutableCopy];
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

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
	
}

-(void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
	
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[(ProjectViewLayout*)collectionView.collectionViewLayout setRemoveAll:YES];
	
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:self.currentItems.count];
	for (NSInteger row=self.currentItems.count-1; row >= 0; row--) {
		if (row != indexPath.row)
			[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
	}
	id keepObject = [self.currentItems objectAtIndex:indexPath.row];
	[collectionView performBatchUpdates:^{
		[self.currentItems removeAllObjects];
		[collectionView deleteItemsAtIndexPaths:paths];
		[self.currentItems addObject:keepObject];
	} completion:^(BOOL finished) {
		[(ProjectViewLayout*)collectionView.collectionViewLayout setRemoveAll:NO];
		[self.currentItems removeAllObjects];
		[collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
		[self.currentItems addObject:keepObject];
		[collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
	}];
}

@end
