//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacSessionViewController.h"

@interface MacSessionViewController()
@end

@implementation MacSessionViewController

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		self.session = aSession;
	}
	return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.busy = NO;
}

-(IBAction)makeBusy:(id)sender
{
	self.busy = ! self.busy;
	self.statusMessage = @"hoo boy";
}

@synthesize session;
@synthesize rootView;
@end

@implementation SessionView
@end