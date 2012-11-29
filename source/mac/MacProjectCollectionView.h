//
//  MacProjectCollectionView.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MacProjectCollectionItem;

@interface MacProjectCollectionView : NSCollectionView

@end

@protocol ProjectCollectionDelegate <NSCollectionViewDelegate>

@optional
-(void)collectionView:(MacProjectCollectionView*)cview deleteBackwards:(id)sender;
-(void)collectionView:(MacProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item;
-(void)collectionView:(MacProjectCollectionView *)cview swipeBackwards:(NSEvent*)event;
-(void)collectionView:(MacProjectCollectionView *)cview renameItem:(MacProjectCollectionItem*)item name:(NSString*)newName;
@end