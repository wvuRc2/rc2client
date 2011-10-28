//
//  MCWebOutputController.h
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCSavedSession;

@protocol MCWebOutputDelegate <NSObject>
-(void)handleImageRequest:(NSURL*)url;
-(void)previewImages:(NSArray*)imageUrls atPoint:(NSPoint)pt;
-(void)executeConsoleCommand:(NSString*)command;
@end

@interface MCWebOutputController : AMViewController<NSTextFieldDelegate>
@property (nonatomic, strong) IBOutlet WebView *webView;
@property (nonatomic, unsafe_unretained) IBOutlet id<MCWebOutputDelegate> delegate;
@property (nonatomic, strong) IBOutlet NSTextField *consoleField;
@property (nonatomic, copy) NSString *inputText;
@property (nonatomic) BOOL canExecute;

-(IBAction)doExecuteQuery:(id)sender;
-(IBAction)executeQueryViaButton:(id)sender;

-(void)restoreSessionState:(RCSavedSession*)savedState;
@end
