//
//  ImageCollectionCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/2/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCImage;

@interface ImageCollectionCell : UICollectionViewCell
@property (nonatomic, weak) RCImage *image;
@end
