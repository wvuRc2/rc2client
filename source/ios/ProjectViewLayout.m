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

@end

@implementation ProjectViewLayout

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
}


-(void)setRemoveAll:(BOOL)removeAll
{
	_removeAll = removeAll;
//	NSLog(@"invalidating layout");
//	[self invalidateLayout];
}


-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
	CGRect bnds = self.collectionView.bounds;
	NSArray *allAttrs = [super layoutAttributesForElementsInRect:rect];
	if (_removeAll) {
		for (UICollectionViewLayoutAttributes *attrs in allAttrs) {
			attrs.alpha = 0;
			attrs.center = CGPointMake(bnds.size.width/2, bnds.size.height/2);
		}
	}
	return allAttrs;
}

-(UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewLayoutAttributes *attrs = [super layoutAttributesForItemAtIndexPath:indexPath];
	if (_removeAll) {
		NSLog(@"customizing attrs");
		attrs.alpha = 0;
		CGRect bnds = self.collectionView.bounds;
		attrs.center = CGPointMake(bnds.size.width/2, bnds.size.height/2);
	}
	return attrs;
}

-(UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
	UICollectionViewLayoutAttributes *attrs = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
	if ([self.deletedItems containsObject:itemIndexPath] || _removeAll) {
		NSLog(@"removing %@", itemIndexPath);
		if (nil == attrs)
			attrs = [super layoutAttributesForItemAtIndexPath:itemIndexPath];
		attrs.alpha = 0;
		CGRect bnds = self.collectionView.bounds;
		attrs.center = CGPointMake(bnds.size.width/2, bnds.size.height/2);
	}
	return attrs;
}

@end
