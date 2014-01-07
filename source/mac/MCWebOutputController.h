//
//  MCWebOutputController.h
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCSavedSession;
@class RCMConsoleTextField;
@class RCFile;
@class RCSession;
@class RCImage;

@protocol MCWebOutputDelegate <NSObject>
-(BOOL)restricted;
-(void)executeConsoleCommand:(NSString*)command;
-(void)displayLinkedFile:(NSString*)filePath atPoint:(NSPoint)pt;
-(RCImage*)imageForTextAttachment:(NSTextAttachment*)tattach;
-(RCSession*)session;
@end

@interface MCWebOutputController : AMViewController<NSTextFieldDelegate, NSUserInterfaceValidations>
@property (nonatomic, strong) IBOutlet NSPopUpButton *historyPopUp;
@property (nonatomic, weak) IBOutlet id<MCWebOutputDelegate> delegate;
@property (nonatomic, strong) IBOutlet RCMConsoleTextField *consoleField;
@property (nonatomic, copy) NSString *inputText;
@property (nonatomic) BOOL canExecute;
@property (nonatomic, readonly) BOOL canIncreaseFontSize;
@property (nonatomic, readonly) BOOL canDecreaseFontSize;
@property (nonatomic) BOOL consoleVisible;
@property (nonatomic) BOOL historyHasItems;
@property (nonatomic) BOOL restrictedMode; //mirrored to session view controller's value
@property (nonatomic, readonly) BOOL enabledTextField;

-(IBAction)doExecuteQuery:(id)sender;
-(IBAction)doClear:(id)sender;
-(IBAction)openInWebBrowser:(id)sender;
-(IBAction)doConsoleBack:(id)sender;
-(IBAction)executeQueryViaButton:(id)sender;
-(IBAction)saveSelectedPDF:(id)sender;
-(IBAction)loadPreviousCommand:(id)sender;
-(IBAction)loadNextCommand:(id)sender;
-(IBAction)doIncreaseFontSize:(id)sender;
-(IBAction)doDecreaseFontSize:(id)sender;

-(void)saveSessionState:(RCSavedSession*)savedState;
-(void)restoreSessionState:(RCSavedSession*)savedState;

-(void)loadLocalFile:(RCFile*)file;
-(void)loadHelpURL:(NSURL*)helpUrl;

-(void)appendAttributedString:(NSAttributedString*)aString;

-(NSTextAttachmentCell*)attachmentCellForAttachment:(NSTextAttachment*)tattach;

@end
