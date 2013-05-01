//
//  RCMMultiImageController.h
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCAbstractViewController.h"

@class RCMImageDetailController;

@interface RCMMultiImageController : MCAbstractViewController
@property (nonatomic, strong) NSArray *availableImages;
@property (nonatomic) NSInteger numberImagesVisible;
@property (nonatomic, copy) BasicBlock didLeaveWindowBlock;
-(void)setDisplayedImages:(NSArray*)imgs;
@end
