//
//  MCMainWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCMainWindowController.h"
#import "RCMAppConstants.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCSession.h"
#import <Vyana/NSMenu+AMExtensions.h>
#import "MCSessionViewController.h"
#import "AppDelegate.h"
#import "RCMacToolbarItem.h"
#import "MCProjectViewController.h"
#import "MCAdminController.h"

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
	self.window.title = [NSString stringWithFormat:@"%@ (%@)", self.window.title, [[Rc2Server sharedInstance] connectionDescription]];
	self.projectController = [[MCProjectViewController alloc] init];
	self.projectController.view.frame = self.detailContainer.frame;
	self.projectController.view.autoresizingMask = self.detailContainer.autoresizingMask;
	NSView *contentView = self.window.contentView;
	[contentView replaceSubview:self.detailContainer with:self.projectController.view];
	self.navController = [[AMMacNavController alloc] initWithRootViewController:self.projectController];
	self.navController.delegate = (id)self;
	RCMacToolbarItem *addItem = [self.window.toolbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
	addItem.actionMenu = self.addToolbarMenu;
	//if the list of projects is refreshed, the current session will be referencing a dealloced project since the workspace
	// keeps a weak reference
	__weak MCMainWindowController *bself = self;
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"projects" options:0 block:^(MAKVONotification *notification) {
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

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	return YES;
}

#pragma mark - meat & potatos

-(void)openSession:(RCWorkspace*)wspace inNewWindow:(BOOL)inNewWindow
{
	[self openSession:wspace file:nil inNewWindow:inNewWindow];
}

-(void)openSession:(RCWorkspace*)wspace file:(RCFile*)initialFile inNewWindow:(BOOL)inNewWindow
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
	}
}

-(IBAction)showAdminTools:(id)sender
{
	if (nil == self.adminController)
		self.adminController = [[MCAdminController alloc] init];
	[self.navController pushViewController:self.adminController animated:YES];
}

@end
