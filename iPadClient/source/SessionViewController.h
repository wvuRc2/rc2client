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
@class BottomViewController;

@interface SessionViewController : UIViewController<MGSplitViewControllerDelegate,RCSessionDelegate,KeyboardViewDelegate,UIDocumentInteractionControllerDelegate> {
	IBOutlet UITextField *textField;
	IBOutlet UITextView *textView;
}
-(id)initWithSession:(RCSession*)session;

@property (nonatomic, strong) IBOutlet UIButton *button1;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet KeyboardView *keyboardView;
@property (nonatomic, strong) IBOutlet MGSplitViewController *splitController;
@property (nonatomic, strong) IBOutlet EditorViewController *editorController;
@property (nonatomic, strong) IBOutlet ConsoleViewController *consoleController;
@property (nonatomic, strong) IBOutlet BottomViewController *bottomController;
@property (weak, nonatomic, readonly) RCSession *session;
@end
