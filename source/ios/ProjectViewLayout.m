//
//  ProjectViewLayout.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/1/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "ProjectViewLayout.h"

@interface ProjectViewLayout ()
@property (strong) NSMutableArray *insertedItems;
@property (strong) NSMutableArray *deletedItems;
@property (strong) NSMutableArray *layoutAttrs;
@property (strong) NSMutableArray *previousAttrs;
@property CGSize contentSize;
@end

#define MARGIN 20

@implementation ProjectViewLayout

-(void)prepareLayout
{
	if (_removeAll) {
		self.previousAttrs = [_layoutAttrs mutableCopy];
	}
	if (nil == self.layoutAttrs)
		self.layoutAttrs = [NSMutableArray array];
	[_layoutAttrs removeAllObjects];
	CGRect cvFrame = self.collectionView.frame;
	CGFloat maxWidth = cvFrame.size.width;
	NSInteger cnt = [[self.collectionView dataSource] collectionView:self.collectionView numberOfItemsInSection:0];
	int row=0, col=0, maxCol=1;
	int widthIncrement = _itemSize.width + MARGIN;
	CGPoint nextCenter = CGPointMake(MARGIN + (_itemSize.width/2), MARGIN + (_itemSize.height/2));
	for (NSInteger i=0; i < cnt; i++,col++) {
		UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		[_layoutAttrs addObject:attrs];
		attrs.center = nextCenter;
		attrs.size = _itemSize;
		nextCenter.x += widthIncrement;
		if ((nextCenter.x + _itemSize.width + MARGIN) > maxWidth) {
			if (col > maxCol)
				maxCol = col;
			col = 0; row++;
			nextCenter.y += MARGIN + _itemSize.height;
			nextCenter.x = MARGIN + (_itemSize.width / 2);
		}
	}
	self.contentSize = CGSizeMake(widthIncrement * (maxCol+1), MARGIN + MARGIN + ((row+1) * _itemSize.height));
}

-(CGSize)collectionViewContentSize
{
	return _contentSize;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
		UICollectionViewLayoutAttributes *attrs = obj;
		return CGRectIntersectsRect(attrs.frame, rect);
	}];
	NSArray *results = [_layoutAttrs filteredArrayUsingPredicate:pred];
	return results;
}

-(UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.layoutAttrs objectAtIndex:indexPath.row];
}



-(void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
	[super prepareForCollectionViewUpdates:updateItems];
	self.deletedItems = [NSMutableArray array];
	self.insertedItems = [NSMutableArray array];
	for (UICollectionViewUpdateItem *update in updateItems) {
		if (update.updateAction == UICollectionUpdateActionInsert)
			[self.insertedItems addObject:update.indexPathAfterUpdate];
		else if (update.updateAction == UICollectionUpdateActionDelete)
			[self.deletedItems addObject:update.indexPathBeforeUpdate];
	}
}

-(void)finalizeCollectionViewUpdates
{
	[super finalizeCollectionViewUpdates];
	self.deletedItems=nil;
	self.insertedItems=nil;
	self.previousAttrs=nil;
}

-(UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
	UICollectionViewLayoutAttributes *attrs = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
	if ([self.deletedItems containsObject:itemIndexPath] || _removeAll) {
		if (nil == attrs)
			attrs = [super layoutAttributesForItemAtIndexPath:itemIndexPath];
		if (nil == attrs)
			attrs = [_previousAttrs objectAtIndex:itemIndexPath.row];
		attrs.alpha = 0;
		CGRect bnds = self.collectionView.bounds;
		attrs.center = CGPointMake(bnds.size.width/2, bnds.size.height/2);
	}
	return attrs;
}

@end
