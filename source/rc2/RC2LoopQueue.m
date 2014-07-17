//
//  RC2LoopQueue.m
//  Rc2Client
//
//  Created by Mark Lilback on 7/24/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "RC2LoopQueue.h"

@interface RC2LoopQueue ()
@property (nonatomic, copy) NSArray *objectArray;
@property (nonatomic) dispatch_group_t dgroup;
@end

@implementation RC2LoopQueue

-(id)initWithObjectArray:(NSArray*)array task:(BasicBlock1Arg)task
{
	if (self = [super init]) {
		self.objectArray = array;
		self.taskBlock = task;
		_dgroup = dispatch_group_create();
	}
	return self;
}

-(void)startTasks
{
	dispatch_queue_t dqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	for (id obj in _objectArray) {
		dispatch_group_async(_dgroup, dqueue, ^{
			_taskBlock(obj);
		});
	}
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		NSLog(@"calling dispatch wait");
		dispatch_group_wait(_dgroup, DISPATCH_TIME_FOREVER);
		NSLog(@"dispatch wait returned");
		if (_completionHandler)
			_completionHandler(self);
	});
}

@end
