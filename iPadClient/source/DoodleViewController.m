//
//  DoodleViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 4/20/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import "DoodleViewController.h"
#import "DoodleView.h"

@interface DoodleViewController ()

@end

@implementation DoodleViewController

-(void)loadView
{
	DoodleView *v = [[DoodleView alloc] initWithFrame:CGRectMake(0, 44, 768, 980)];
	self.view = v;
	v.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	CGRect f = self.view.superview.bounds;
	f.origin.y += 44;
	f.size.height -= 44;
	self.view.frame = f;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
