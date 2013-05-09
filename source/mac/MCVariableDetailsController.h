//
//  MCVariableDetailsController.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/8/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCVariable;

@interface MCVariableDetailsController : NSViewController
@property (nonatomic, strong) RCVariable *variable;

-(BOOL)variableSupported:(RCVariable*)var;
-(NSSize)calculateContentSize:(NSSize)curSize;
@end
