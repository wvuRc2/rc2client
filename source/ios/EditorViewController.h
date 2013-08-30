//
//  EditorViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;
@class RCSavedSession;
@class RCSession;

@interface EditorViewController : UIViewController<UIPopoverControllerDelegate,UITextViewDelegate>
@property (nonatomic, strong) RCFile *currentFile;
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, assign) BOOL externalKeyboardVisible;

-(IBAction)doExecute:(id)sender;
-(IBAction)doShowFiles:(id)sender;
-(IBAction)doClear:(id)sender;
-(IBAction)doDeleteFile:(id)sender;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doRevertFile:(id)sender;
-(IBAction)presentDropboxImport:(id)sender;
-(IBAction)doSaveFile:(id)sender;
-(IBAction)toggleHand:(id)sender;

-(BOOL)isEditorFirstResponder;
-(void)editorResignFirstResponder;
-(NSString*)editorContents;
-(void)reloadFileData;
-(void)adjustLineNumbers;

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress;
-(void)loadFile:(RCFile*)file; //shows progress
-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
