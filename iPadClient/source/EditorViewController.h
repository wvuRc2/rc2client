//
//  EditorViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeyboardView.h"

@class RCFile;
@class RCSavedSession;
@class RCSession;

@interface EditorViewController : UIViewController<KeyboardViewDelegate,UIPopoverControllerDelegate,UITextViewDelegate>
//@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *executeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *syncButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *openFileButtonItem;
@property (nonatomic, strong) IBOutlet UILabel *docTitleLabel;
@property (nonatomic, strong) IBOutlet UIButton *handButton;
@property (nonatomic, strong) RCFile *currentFile;
@property (nonatomic, strong) RCSession *session;

-(IBAction)doExecute:(id)sender;
-(IBAction)doShowFiles:(id)sender;
-(IBAction)doActionMenu:(id)sender;
-(IBAction)doClear:(id)sender;
-(IBAction)doDeleteFile:(id)sender;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doRevertFile:(id)sender;
-(IBAction)presentDropboxImport:(id)sender;
-(IBAction)doSaveFile:(id)sender;
-(IBAction)toggleHand:(id)sender;

-(void)setInputView:(id)inputView;
-(BOOL)isEditorFirstResponder;

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress;
-(void)loadFile:(RCFile*)file; //shows progress
-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
