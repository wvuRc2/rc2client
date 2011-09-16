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
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) RCSession *session;

-(void)restoreSessionState:(RCSavedSession*)savedState;
-(IBAction)doClear:(id)sender;
-(IBAction)doActionSheet:(id)sender;
@end
