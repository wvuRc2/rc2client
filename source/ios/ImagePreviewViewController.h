//
//  ImagePreviewViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCImage;

@interface ImagePreviewViewController : UIViewController
@property (nonatomic, copy) NSArray *images;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, copy) void (^dismissalBlock)(ImagePreviewViewController *controller);
@property (nonatomic, copy) void (^detailsBlock)(ImagePreviewViewController *controller);
-(void)presentationComplete;
-(CGRect)targetFrame;
@end
