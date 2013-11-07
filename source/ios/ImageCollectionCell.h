//
//  ImageCollectionCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/2/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCImage;

@protocol ImageCollectionCellDelegate;

@interface ImageCollectionCell : UICollectionViewCell
@property (nonatomic, weak) RCImage *image;
@property (nonatomic, weak) id<ImageCollectionCellDelegate> imageDelegate;
@end

@protocol ImageCollectionCellDelegate <NSObject>
-(void)imageCollectionCell:(ImageCollectionCell*)cell showActionsFromRect:(CGRect)touchRect;
-(void)imageCollectionCell:(ImageCollectionCell*)cell selectImageFrom:(CGRect)rect;
@end