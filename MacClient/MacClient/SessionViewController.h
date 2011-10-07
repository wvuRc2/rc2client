//
//  SessionViewController.h
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCSession;


@interface SessionViewController : AMViewController
@property (nonatomic, strong) RCSession *session;

-(id)initWithSession:(RCSession*)aSession;
@end

@interface SessionView : AMControlledView
@end
