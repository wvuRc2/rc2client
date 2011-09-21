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

@interface EditorViewController : UIViewController<KeyboardViewDelegate,UIPopoverControllerDelegate,UITextViewDelegate>
@property (nonatomic, assign) IBOutlet UITextView *textView;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *executeButton;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *actionButtonItem;
@property (nonatomic, assign) IBOutlet UILabel *docTitleLabel;
@property (nonatomic, retain) RCFile *currentFile;

-(IBAction)doExecute:(id)sender;
-(IBAction)doShowFiles:(id)sender;
-(IBAction)doActionMenu:(id)sender;
-(IBAction)doClear:(id)sender;
-(IBAction)doDeleteFile:(id)sender;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doRevertFile:(id)sender;
-(IBAction)presentDropboxImport:(id)sender;

-(void)loadFile:(RCFile*)file;
-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
