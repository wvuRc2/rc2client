//
//  RCMMultiUpView.h
//  Rc2Client
//
//  Created by Mark Lilback on 4/12/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol RCMMultiUpChildView;

typedef NS_ENUM(NSUInteger, MultiUpMode) {
	MultiUpQuantity_1,
	MultiUpQuantity_2,
	MultiUpQuantity_4
};

@interface RCMMultiUpView : NSView
//array of objects conforming to MacMultiUpChildView
@property (nonatomic, copy) NSArray *viewControllers;
@property (nonatomic, assign) MultiUpMode mode;
@end


@protocol RCMMultiUpChildView <NSObject>

@property (weak) NSLayoutConstraint *multiXConstraint;
@property (weak) NSLayoutConstraint *multiYConstraint;
@property (weak) NSLayoutConstraint *multiWConstraint;
@property (weak) NSLayoutConstraint *multiHConstraint;


@end