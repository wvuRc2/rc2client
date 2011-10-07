//
//  SessionWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SessionViewController;

@interface SessionWindowController : NSWindowController<NSWindowDelegate>
@property (nonatomic, strong) SessionViewController *viewController;

- (id)initWithViewController:(SessionViewController*)svc;
@end
