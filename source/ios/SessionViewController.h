//
//  SessionViewController.h
//  rc2-iPad
//
//  Created by Mark Lilback on 8/5/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AbstractTopViewController.h"
#import "RCSession.h"

@class EditorViewController;
@class ConsoleViewController;

@interface SessionViewController : AbstractTopViewController<RCSessionDelegate,UIDocumentInteractionControllerDelegate>
-(id)initWithSession:(RCSession*)session;
@property (nonatomic, strong) IBOutlet EditorViewController *editorController;
@property (nonatomic, strong) IBOutlet ConsoleViewController *consoleController;
//@property (nonatomic, weak) IBOutlet UIBarButtonItem *executeButton;
@property (weak, nonatomic, readonly) RCSession *session;

-(IBAction)showControls:(id)sender;
-(IBAction)toggleMicrophone:(id)sender;
@end
