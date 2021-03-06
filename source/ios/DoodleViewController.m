//
//  DoodleViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 4/20/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "DoodleViewController.h"
#import "DoodleView.h"

@interface DoodleViewController ()

@end

@implementation DoodleViewController

-(void)loadView
{
	DoodleView *v = [[DoodleView alloc] initWithFrame:CGRectMake(0, 44, 768, 936)];
	self.view = v;
	v.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	CGRect f = self.view.superview.bounds;
	f.origin.y += 44;
	f.size.height -= 88;
	self.view.frame = f;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
