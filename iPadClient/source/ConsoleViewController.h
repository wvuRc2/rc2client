//
//  ConsoleViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCSession;
@class RCSavedSession;

@interface ConsoleViewController : UIViewController<UIWebViewDelegate>
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UIButton *executeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) RCSession *session;

-(void)restoreSessionState:(RCSavedSession*)savedState;
-(IBAction)doClear:(id)sender;
-(IBAction)doActionSheet:(id)sender;
-(IBAction)doExecute:(id)sender;
-(IBAction)doBack:(id)sender;
@end

@interface ConsoleView : UIView
@end