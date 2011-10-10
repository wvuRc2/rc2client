//
//  MacSessionViewController.h
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"

@class RCSession;

@interface MacSessionViewController : MacClientAbstractViewController
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, strong) IBOutlet NSSplitView *splitView;

-(id)initWithSession:(RCSession*)aSession;
-(IBAction)makeBusy:(id)sender;
@end

@interface SessionView : AMControlledView
@end
