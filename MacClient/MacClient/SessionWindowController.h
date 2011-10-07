//
//  SessionWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MacSessionViewController;

@interface SessionWindowController : NSWindowController<NSWindowDelegate>
@property (nonatomic, strong) MacSessionViewController *viewController;
@property (nonatomic, strong) IBOutlet NSView *theView;
- (id)initWithViewController:(MacSessionViewController*)svc;
@end
