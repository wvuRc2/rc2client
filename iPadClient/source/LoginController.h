//
//  LoginController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginController : UIViewController<UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *useridField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *busyWheel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *hostControl;
@property (nonatomic, copy) BasicBlock loginCompleteHandler;

-(IBAction)doLogin:(id)sender;
@end
