//
//  LoginController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginController : UIViewController<UITextFieldDelegate>
@property (nonatomic, assign) IBOutlet UITextField *useridField;
@property (nonatomic, assign) IBOutlet UITextField *passwordField;
@property (nonatomic, assign) IBOutlet UIButton *loginButton;
@property (nonatomic, assign) IBOutlet UIActivityIndicatorView *busyWheel;
@property (nonatomic, assign) IBOutlet UISegmentedControl *hostControl;
@property (nonatomic, copy) BasicBlock loginCompleteHandler;

-(IBAction)doLogin:(id)sender;
@end
