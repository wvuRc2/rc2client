//
//  SessionViewController.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"
#import "RCSession.h"
#import "KeyboardView.h"

@class EditorViewController;
@class ConsoleViewController;

@interface SessionViewController : UIViewController<MGSplitViewControllerDelegate,RCSessionDelegate,KeyboardExecuteDelegate,UIDocumentInteractionControllerDelegate> {
	IBOutlet UITextField *textField;
	IBOutlet UITextView *textView;
}
-(id)initWithSession:(RCSession*)session;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIButton *button1;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet KeyboardView *keyboardView;
@property (nonatomic, strong) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, strong) IBOutlet EditorViewController *editorController;
@property (nonatomic, strong) IBOutlet ConsoleViewController *consoleController;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *controlButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *mikeButton;
@property (weak, nonatomic, readonly) RCSession *session;

-(IBAction)showControls:(id)sender;
-(IBAction)toggleMicrophone:(id)sender;
@end
