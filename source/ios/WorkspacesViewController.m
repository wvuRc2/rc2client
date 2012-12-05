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
#import "Rc2Server.h"

@interface WorkspacesViewController ()
@property (nonatomic, strong) UISplitViewController *splitController;
@property (nonatomic, strong) DetailsViewController *detailsController;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) WorkspaceTableController *rootWorkspaceController;
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
	self.rootWorkspaceController = wtc;
	self.splitController = [[UISplitViewController alloc] init];
	self.splitController.viewControllers = [NSArray arrayWithObjects:self.navController, self.detailsController, nil];
	self.splitController.delegate = self;
	[self.splitController setValue:[NSNumber numberWithFloat:260.0] forKey:@"_masterColumnWidth"];
	[self addChildViewController:self.splitController];
	[self.splitController didMoveToParentViewController:self];
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
	self.view = view;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[view addSubview:self.splitController.view];	
	
	[self.kvoTokens addObject:[[Rc2Server sharedInstance] addObserverForKeyPath:@"selectedWorkspace" task:^(id obj, NSDictionary *change) {
		if (nil == [[Rc2Server sharedInstance] selectedWorkspace])
			[wtc clearSelection];
	}]];
	[self storeNotificationToken:[[NSNotificationCenter defaultCenter] addObserverForName:WorkspaceItemsChangedNotification object:nil queue:nil 
																			   usingBlock:^(NSNotification *note) 
	{
//		wtc.workspaceItems = [[Rc2Server sharedInstance] workspaceItems];
	}
	]];
//	if ([[Rc2Server sharedInstance] loggedIn])
//		wtc.workspaceItems = [Rc2Server sharedInstance].workspaceItems;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view.
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
@end
