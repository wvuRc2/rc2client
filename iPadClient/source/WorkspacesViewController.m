//
//  WorkspacesViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "WorkspacesViewController.h"
#import "DetailsViewController.h"
#import "WorkspaceTableController.h"
#import "MGSplitViewController.h"

@interface WorkspacesViewController ()
@property (nonatomic, strong) UISplitViewController *splitController;
@property (nonatomic, strong) DetailsViewController *detailsController;
@property (nonatomic, strong) UINavigationController *navController;
@end

@implementation WorkspacesViewController

- (id)init
{
	return [super initWithNibName:nil bundle:nil];
}

-(void)loadView
{
	self.detailsController = [[DetailsViewController alloc] init];
	WorkspaceTableController *wtc = [[WorkspaceTableController alloc] initWithNibName:@"WorkspaceTableController" bundle:nil];
	self.navController = [[UINavigationController alloc] initWithRootViewController:wtc];
	wtc.navigationItem.title = @"Workspaces";
	self.splitController = [[UISplitViewController alloc] init];
	self.splitController.viewControllers = [NSArray arrayWithObjects:self.navController, self.detailsController, nil];
	self.splitController.delegate = self;
	[self.splitController setValue:[NSNumber numberWithFloat:230.0] forKey:@"_masterColumnWidth"];
//	self.splitController = [[MGSplitViewController alloc] initWithNibName:nil bundle:nil];
//	self.splitController.masterViewController = self.navController;
//	self.splitController.detailViewController = self.detailsController;
//	self.splitController.showsMasterInPortrait = YES;
	[self addChildViewController:self.splitController];
	[self.splitController didMoveToParentViewController:self];
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
	self.view = view;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[view addSubview:self.splitController.view];
//	if (UIInterfaceOrientationIsLandscape([TheApp statusBarOrientation]))
//		self.splitController.splitPosition = 320;
//	else
//		self.splitController.splitPosition = 260;
	
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.splitController.view.frame = self.view.bounds;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
	return NO;
}

@synthesize splitController=_splitController;
@synthesize detailsController=_detailsController;
@synthesize navController=_navController;
@end
