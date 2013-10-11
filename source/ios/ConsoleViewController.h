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
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UIButton *executeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, strong) RCSession *session;

-(void)saveSessionState:(RCSavedSession*)savedState;
-(void)restoreSessionState:(RCSavedSession*)savedState;
-(IBAction)doClear:(id)sender;
-(IBAction)doActionSheet:(id)sender;
-(IBAction)doExecute:(id)sender;
-(IBAction)doBack:(id)sender;

-(void)loadHelpURL:(NSURL*)url;
-(void)loadLocalFileURL:(NSURL*)url;
-(void)variablesUpdated;

-(void)appendAttributedString:(NSAttributedString*)aString;
@end

@interface ConsoleView : UIView
@end
