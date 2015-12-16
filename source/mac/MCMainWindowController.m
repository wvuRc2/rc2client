//
//  MCMainWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "Rc2-Swift.h"
#import "MCMainWindowController.h"
#import "MCAppConstants.h"
#import "RCSession.h"
#import <Vyana/NSMenu+AMExtensions.h>
#import "MCSessionViewController.h"
#import "AppDelegate.h"
#import "RCMacToolbarItem.h"
#import "MCProjectViewController.h"
#import "MCAdminController.h"
#import "RCMPDFViewController.h"

@interface MCMainWindowController()
@property (strong) NSMutableArray *kvoObservers;
@property (nonatomic, strong) MCProjectViewController *projectController;
@property (nonatomic, strong) MCSessionViewController *currentSessionController;
@property (nonatomic, strong) MCAdminController *adminController;
@end

#pragma mark -

@implementation MCMainWindowController

#pragma mark - init/load

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MacMainWindow"])) {
		self.kvoObservers = [NSMutableArray array];
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	Rc2RestServer *server = [Rc2RestServer sharedInstance];
	self.window.title = [NSString stringWithFormat:@"%@ (%@)", self.window.title, server.connectionDescription];
	self.projectController = [[MCProjectViewController alloc] init];
	self.projectController.view.frame = self.detailContainer.frame;
	self.projectController.view.autoresizingMask = self.detailContainer.autoresizingMask;
	NSView *contentView = self.window.contentView;
	[contentView replaceSubview:self.detailContainer with:self.projectController.view];
	self.navController = [[AMMacNavController alloc] initWithRootViewController:self.projectController];
	self.navController.delegate = (id)self;
	RCMacToolbarItem *addItem = [self.window.toolbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
	addItem.actionMenu = self.addToolbarMenu;
	[self.projectController didBecomeVisible];
	//if the list of projects is refreshed, the current session will be referencing a dealloced project since the workspace
	// keeps a weak reference
	__weak typeof(self) bself = self;
	[self observeTarget:server keyPath:@"loginSession" options:0 block:^(MAKVONotification *notification) {
		if (bself.currentSessionController && nil == bself.currentSessionController.view.window)
			bself.currentSessionController = nil;
	}];
}

-(void)windowWillClose:(NSNotification *)note
{
	[self.window makeFirstResponder:nil];
	if (self.currentSessionController) {
		[self.currentSessionController saveChanges];
		self.currentSessionController.session.delegate = nil;
		self.currentSessionController.session=nil;
		self.currentSessionController=nil;
	}
}


-(void)displayPdfFile:(RCFile*)file
{
	RCMPDFViewController *pvc = [[RCMPDFViewController alloc] init];
	[pvc view]; //load from nib
	[pvc loadPdfFile:file];
	[self showViewController:pvc];
}

-(void)showViewController:(AMViewController*)controller
{
	[self.navController pushViewController:controller animated:YES];
}

-(void)popCurrentViewController
{
	[self.navController popViewControllerAnimated:YES];
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	return YES;
}

#pragma mark - meat & potatos

-(void)openSession:(Rc2Workspace*)wspace
{
	[self openSession:wspace file:nil];
}

-(void)openSession:(Rc2Workspace*)wspace file:(RCFile*)initialFile
{
	if (self.currentSessionController.session.workspace != wspace) {
		RCSession *session = [[RCSession alloc] initWithWorkspace:wspace serverResponse:nil];
		self.currentSessionController = [[MCSessionViewController alloc] initWithSession:session];
	}
	if (initialFile)
		self.currentSessionController.session.initialFileSelection = initialFile;
	[self.navController pushViewController:self.currentSessionController animated:YES];
}

#pragma mark - nav controller

-(void)macNavController:(AMMacNavController*)navController 
  didShowViewController:(NSViewController*)viewController 
			   animated:(BOOL)animated
{
	while (self.rightStatusView.subviews.count > 0)
		[self.rightStatusView.subviews.firstObject removeFromSuperview];
	if ([viewController isKindOfClass:[MCAbstractViewController class]]) {
		MCAbstractViewController *avc = (MCAbstractViewController*)viewController;
		NSView *view = [avc rightStatusView];
		if (view) {
			view.frame = self.rightStatusView.bounds;
			[self.rightStatusView addSubview:view];
		}
		[avc didBecomeVisible];
	}
}

#pragma mark - actions

-(IBAction)doBackToMainView:(id)sender
{
	if (self.navController.canPopViewController) {
		[self.navController popViewControllerAnimated:YES];
	} else if (self.navController.topViewController == self.projectController && !self.projectController.showingProjects) {
		[self.projectController displayTopLevel];
	}
}

-(IBAction)showAdminTools:(id)sender
{
	if (nil == self.adminController)
		self.adminController = [[MCAdminController alloc] init];
	[self.navController pushViewController:self.adminController animated:YES];
}

@end
