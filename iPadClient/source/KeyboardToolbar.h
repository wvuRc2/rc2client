//
//  KeyboardToolbar.h
//  iPadClient
//
//  Created by Mark Lilback on 6/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KeyboardToolbarDelegate;

@interface KeyboardToolbar : NSObject
@property (nonatomic, weak) id<KeyboardToolbarDelegate> delegate;
@property (nonatomic, strong) UIView *view;
@end

@protocol KeyboardToolbarDelegate <NSObject>
-(void)keyboardToolbar:(KeyboardToolbar*)tbar insertString:(NSString*)str;
-(void)keyboardToolbarExecute:(KeyboardToolbar*)tbar;
@end