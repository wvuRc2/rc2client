//
//  kTController.h
//  Rc2Client
//
//  Created by Mark Lilback on 9/30/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface kTController : NSObject
@property (nonatomic, copy, readonly) NSArray *panels;
@property (nonatomic, strong, readonly) UIView *view;
@property (nonatomic, strong) UIInputView *inputView;

-(void)nextPanel:(id)sender;
-(void)previousPanel:(id)sender;

@end
