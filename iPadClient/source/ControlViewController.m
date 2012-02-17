//
//  ControlViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "ControlViewController.h"

@implementation ControlViewController

- (id)init
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
	}
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(IBAction)changeMode:(id)sender
{
	NSLog(@"change mode:%d", self.modeControl.selectedSegmentIndex);
}

@synthesize modeControl;
@end
