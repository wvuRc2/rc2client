//
//  CoolButton.h
//  CoolButtons
//
//  Created by Jess Martin on 4/14/11.
//  Copyright 2011 Relevance, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CoolButton : UIButton {
    UIColor *_buttonColor;
    UIView *_innerView;
    CALayer *_highlightLayer;
}

@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, strong) UIView *innerView;
@property (nonatomic, strong) CALayer *highlightLayer;

@end
