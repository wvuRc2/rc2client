//
//  MCProjectCollectionView.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCProjectCollectionItem;
@class RCProject;

@interface MCProjectCollectionView : NSCollectionView

@end

@protocol ProjectCollectionDelegate <NSCollectionViewDelegate>

@optional
-(void)collectionView:(MCProjectCollectionView*)cview deleteBackwards:(id)sender;
-(void)collectionView:(MCProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item;
-(void)collectionView:(MCProjectCollectionView *)cview swipeBackwards:(NSEvent*)event;
-(void)collectionView:(MCProjectCollectionView *)cview renameItem:(MCProjectCollectionItem*)item name:(NSString*)newName;
-(void)collectionView:(MCProjectCollectionView *)cview showShareInfo:(RCProject*)project fromRect:(NSRect)rect;
@end