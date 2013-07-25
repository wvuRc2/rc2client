//
//  RC2LoopQueue.h
//  Rc2Client
//
//  Created by Mark Lilback on 7/24/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RC2LoopQueue : NSObject
@property (nonatomic, copy) void(^completionHandler)(RC2LoopQueue *queue);
@property (nonatomic, copy) BasicBlock1Arg taskBlock;

-(id)initWithObjectArray:(NSArray*)array task:(BasicBlock1Arg)task;

-(void)startTasks;
@end
