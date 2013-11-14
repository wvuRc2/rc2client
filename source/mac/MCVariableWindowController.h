//
//  MCVariableWindowController.h
//  Rc2Client
//
//  Created by Mark Lilback on 11/14/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCVariableDisplayController;

@interface MCVariableWindowController : NSWindowController
@property (nonatomic, strong) MCVariableDisplayController *displayController;
@property (nonatomic, copy, readonly) NSString *saveIdentifier;
@end
