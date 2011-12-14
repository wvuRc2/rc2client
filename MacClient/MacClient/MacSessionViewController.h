//
//  MacSessionViewController.h
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"
#import "RCSession.h"

@class RCMTextView;

@interface MacSessionViewController : MacClientAbstractViewController<RCSessionDelegate,NSSplitViewDelegate,NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, strong) IBOutlet NSSplitView *contentSplitView;
@property (nonatomic, strong) IBOutlet NSTableView *fileTableView;
@property (nonatomic, strong) IBOutlet NSView *fileContainerView;
@property (nonatomic, strong) IBOutlet RCMTextView *editView;
@property (nonatomic, strong) IBOutlet NSButton *executeButton;

-(id)initWithSession:(RCSession*)aSession;
-(IBAction)toggleFileList:(id)sender;
-(IBAction)makeBusy:(id)sender;
-(IBAction)executeScript:(id)sender;
-(IBAction)importFile:(id)sender;
-(IBAction)createNewFile:(id)sender;
-(void)saveChanges;

-(void)saveSessionState;
-(void)restoreSessionState:(RCSavedSession*)savedState;

@end

@interface SessionView : AMControlledView
@end
