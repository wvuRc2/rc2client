//
//  MCWebOutputController.h
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCSavedSession;
@class RCMConsoleTextField;

@protocol MCWebOutputDelegate <NSObject>
-(void)handleImageRequest:(NSURL*)url;
-(void)previewImages:(NSArray*)imageUrls atPoint:(NSPoint)pt;
-(void)executeConsoleCommand:(NSString*)command;
@end

@interface MCWebOutputController : AMViewController<NSTextFieldDelegate>
@property (nonatomic, strong) IBOutlet WebView *webView;
@property (nonatomic, strong) IBOutlet NSPopUpButton *historyPopUp;
@property (nonatomic, unsafe_unretained) IBOutlet id<MCWebOutputDelegate> delegate;
@property (nonatomic, strong) IBOutlet RCMConsoleTextField *consoleField;
@property (nonatomic, copy) NSString *inputText;
@property (nonatomic) BOOL canExecute;
@property (nonatomic) BOOL consoleVisible;
@property (nonatomic) BOOL historyHasItems;

-(IBAction)doExecuteQuery:(id)sender;
-(IBAction)doClear:(id)sender;
-(IBAction)openInWebBrowser:(id)sender;
-(IBAction)executeQueryViaButton:(id)sender;
-(IBAction)saveSelectedPDF:(id)sender;
-(IBAction)goBack:(id)sender;
-(IBAction)loadPreviousCommand:(id)sender;
-(IBAction)loadNextCommand:(id)sender;

-(void)saveSessionState:(RCSavedSession*)savedState;
-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
