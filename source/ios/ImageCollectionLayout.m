//
//  ImageCollectionLayout.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/3/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ImageCollectionLayout.h"

@interface ImageCollectionLayout ()
@property (nonatomic, copy) NSArray *layoutInfo;
@property (nonatomic) BOOL frozen;
@end

@implementation ImageCollectionLayout

-(id)init
{
	if ((self = [super init])) {
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateLayout) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	}
	return self;
}

-(void)dealloc
{
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(CGSize)collectionViewContentSize
{
	return self.collectionView.frame.size;
}

-(void)prepareLayout
{
	if (self.frozen)
		return;
	CGSize viewSize = self.collectionView.frame.size;
	if (viewSize.height > viewSize.width)
		[self layoutPortrait2Up];
	else
		[self layoutLandscape2Up];
}

-(void)addHiddenLayoutAttributes:(NSInteger)row array:(NSMutableArray*)info
{
	UICollectionViewLayoutAttributes *attrs1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
	attrs1.hidden = YES;
	[info addObject:attrs1];
}

-(void)layoutPortrait2Up
{
	NSMutableArray *info = [NSMutableArray arrayWithCapacity:4];
	CGSize viewSize = self.collectionView.frame.size;
	viewSize.height -= 100;
	CGFloat height = floorf(MIN(viewSize.width-40, (viewSize.height/2)-60) + 38);
	CGFloat width = height - 38;
	CGFloat x = floorf((viewSize.width-width)/2);
	CGFloat y = 20;
	UICollectionViewLayoutAttributes *attrs1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	attrs1.frame = CGRectMake(x, y, width, height);
	[info addObject:attrs1];
	y += 20 + height;
	UICollectionViewLayoutAttributes *attrs2 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	attrs2.frame = CGRectMake(x, y, width, height);
	[info addObject:attrs2];
	[self addHiddenLayoutAttributes:2 array:info];
	[self addHiddenLayoutAttributes:3 array:info];
	self.layoutInfo = info;
}

-(void)layoutLandscape2Up
{
	NSMutableArray *info = [NSMutableArray arrayWithCapacity:4];
	CGSize viewSize = self.collectionView.frame.size;
	CGFloat width = floorf((viewSize.width - 60)/2);
	CGFloat height = width + 38;
	CGFloat y = floorf((viewSize.height-height)/2);
	UICollectionViewLayoutAttributes *attrs1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	attrs1.frame = CGRectMake(20, y, width, height);
	[info addObject:attrs1];
	UICollectionViewLayoutAttributes *attrs2 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	attrs2.frame = CGRectMake(width + 40, y, width, height);
	[info addObject:attrs2];
	[self addHiddenLayoutAttributes:2 array:info];
	[self addHiddenLayoutAttributes:3 array:info];
	self.layoutInfo = info;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:4];
	for (UICollectionViewLayoutAttributes *attr in self.layoutInfo) {
		if (CGRectIntersectsRect(attr.frame, rect))
			[a addObject:attr];
	}
	return a;
}

-(UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.layoutInfo objectAtIndex:indexPath.row];
}

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
	return YES;
}

-(void)prepareForTransitionToLayout:(UICollectionViewLayout *)newLayout
{
	self.frozen = YES;
}
@end
