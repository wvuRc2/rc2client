//
//  ImagePickerController.h
//  iPadClient
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCImage;

@interface ImagePickerController : UITableViewController
@property (nonatomic, copy) NSArray *images;
@property (nonatomic, strong) RCImage *selectedImage;
@property (nonatomic, copy) BasicBlock selectionHandler;
@end
