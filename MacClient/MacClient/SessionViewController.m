//
//  SessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "SessionViewController.h"

@implementation SessionViewController

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"SessionViewController" bundle:nil];
	if (self) {
		self.session = aSession;
	}
	return self;
}

@synthesize session;
@end

@implementation SessionView

@end