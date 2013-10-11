//
//  ImagePreviewTransition.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePreviewTransition : NSObject<UIViewControllerAnimatedTransitioning>
@property (nonatomic, weak) UIViewController *presenting;
@property (nonatomic, weak) UIViewController *presented;
@property (nonatomic, assign) CGRect srcRect;
@property (nonatomic, assign) BOOL isDismissal;
@end
