//
//  iSettingsController.h
//  Rc2
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GradientButton;

@interface iSettingsController : UIViewController<UITextFieldDelegate>
@property (nonatomic, strong) UIPopoverController *containingPopover;
@end
