//
//  MCVariableDisplayController.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/8/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCVariable;
@class RCSession;

@interface MCVariableDisplayController : NSViewController
@property (nonatomic, weak) RCSession *session;
@property (nonatomic, strong) RCVariable *variable;
@property (nonatomic, weak) NSPopover *popover; //needed to resize when switching content type

-(BOOL)variableSupported:(RCVariable*)var;
-(NSSize)calculateContentSize:(NSSize)curSize;
@end
