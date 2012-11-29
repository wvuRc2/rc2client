//
//  MacMainWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MacMainWindowController.h"
#import "RCMAppConstants.h"
#import "MacMainViewController.h"
#import "Rc2Server.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCSession.h"
#import "WorkspaceViewController.h"
#import <Vyana/NSMenu+AMExtensions.h>
#import "MacSessionViewController.h"
#import "AppDelegate.h"
#import "RCMacToolbarItem.h"
#import "MacProjectViewController.h"

@interface MacMainWindowController()
@property (strong) NSMutableArray *kvoObservers;
@property (nonatomic, strong) MacProjectViewController *projectController;
@property (nonatomic, strong) MacSessionViewController *currentSessionController;
@end

#pragma mark -

@implementation MacMainWindowController

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
	self.projectController = [[MacProjectViewController alloc] init];
	self.projectController.view.frame = self.detailContainer.frame;
	self.projectController.view.autoresizingMask = self.detailContainer.autoresizingMask;
	NSView *contentView = self.window.contentView;
	[contentView replaceSubview:self.detailContainer with:self.projectController.view];
	self.navController = [[AMMacNavController alloc] initWithRootViewController:self.projectController];
	self.navController.delegate = (id)self;
	RCMacToolbarItem *addItem = [self.window.toolbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
	addItem.actionMenu = self.addToolbarMenu;
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
		self.currentSessionController = [[MacSessionViewController alloc] initWithSession:session];
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
	if ([viewController isKindOfClass:[MacClientAbstractViewController class]]) {
		NSView *view = [(id)viewController rightStatusView];
		if (view) {
			view.frame = self.rightStatusView.bounds;
			[self.rightStatusView addSubview:view];
		}
	}
}

#pragma mark - actions

-(IBAction)doBackToMainView:(id)sender
{
	if (self.navController.canPopViewController) {
		[self.navController popViewControllerAnimated:YES];
	}
}

-(IBAction)doOpenSession:(id)sender
{
}

-(IBAction)doOpenSessionInNewWindow:(id)sender
{
}

@end
