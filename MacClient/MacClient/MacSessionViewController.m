//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacSessionViewController.h"
#import "MCWebOutputController.h"

@interface MacSessionViewController() {
	BOOL __didInit;
}
@property (nonatomic, strong) MCWebOutputController *outputController;
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
	if (!__didInit) {
		self.outputController = [[MCWebOutputController alloc] init];
		NSView *croot = [self.splitView.subviews objectAtIndex:1];
		[croot addSubview:self.outputController.view];
		self.outputController.view.frame = croot.bounds;
		self.busy = NO;
		__didInit=YES;
	}
}

-(IBAction)makeBusy:(id)sender
{
	self.busy = ! self.busy;
	self.statusMessage = @"hoo boy";
}

@synthesize session;
@synthesize splitView;
@synthesize outputController;
@end

@implementation SessionView
@end