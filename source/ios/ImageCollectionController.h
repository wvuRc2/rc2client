//
//  ImageCollectionController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/2/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "AbstractTopViewController.h"

@interface ImageCollectionController : AbstractTopViewController
@property (nonatomic, copy) NSArray *images;
@property (nonatomic) NSUInteger initialImageIndex;

@end
