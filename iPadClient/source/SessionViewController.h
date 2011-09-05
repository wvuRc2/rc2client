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

@class EditorViewController;
@class ConsoleViewController;
@class BottomViewController;
@class KeyboardView;

@interface SessionViewController : UIViewController<MGSplitViewControllerDelegate,RCSessionDelegate> {
	IBOutlet UITextField *textField;
	IBOutlet UITextView *textView;
}
-(id)initWithSession:(RCSession*)session;

@property (nonatomic, retain) IBOutlet UIButton *button1;
@property (nonatomic, assign) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet KeyboardView *keyboardView;
@property (nonatomic, retain) IBOutlet MGSplitViewController *innerSplitController;
@property (nonatomic, retain) IBOutlet MGSplitViewController *outerSplitController;
@property (nonatomic, retain) IBOutlet EditorViewController *editorController;
@property (nonatomic, retain) IBOutlet ConsoleViewController *consoleController;
@property (nonatomic, retain) IBOutlet BottomViewController *bottomController;
@property (nonatomic, readonly) RCSession *session;
@end
