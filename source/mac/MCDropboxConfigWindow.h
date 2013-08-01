//
//  MCDropboxConfigWindow.h
//  Rc2Client
//
//  Created by Mark Lilback on 8/1/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class RCWorkspace;

@interface MCDropboxConfigWindow : NSWindowController
-(id)initWithWorkspace:(RCWorkspace*)wspace;
@property (copy) BasicBlock1IntArg handler; //1=save, 0 = cancel, -1 = disable. action will have been taken
@end
