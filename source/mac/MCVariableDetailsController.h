//
//  MCVariableDetailsController.h
//  Rc2Client
//
//  Created by Mark Lilback on 11/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCVariable;
@protocol MCVariableDetailsDelegate;

@interface MCVariableDetailsController : NSViewController
@property (nonatomic, strong) RCVariable *variable;
@property (nonatomic, weak) id<MCVariableDetailsDelegate> variableDelegate;
@property (nonatomic, readonly) CGFloat contentWidth;
-(NSSize)calculateContentSize:(NSSize)curSize;
@end

@protocol MCVariableDetailsDelegate <NSObject>

-(void)showVariableDetails:(RCVariable*)variable;

@end