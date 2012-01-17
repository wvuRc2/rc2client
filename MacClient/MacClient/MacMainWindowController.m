//
//  MacMainWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
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

@interface MacMainWindowController()
@property (strong) NSMutableArray *kvoObservers;
@property (nonatomic, strong) MacMainViewController *mainViewController;
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
	self.mainViewController = [[MacMainViewController alloc] init];
	self.mainViewController.view.frame = self.detailContainer.frame;
	NSView *contentView = self.window.contentView;
	[contentView replaceSubview:self.detailContainer with:self.mainViewController.view];
	self.navController = [[AMMacNavController alloc] initWithRootViewController:self.mainViewController];
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
	SEL action = [item action];
	if (@selector(doBackToMainView:) == action) {
		if (self.mainViewController.view.superview == nil) return YES;
		return NO;
	} else if (@selector(doOpenSession:) == action || @selector(doOpenSessionInNewWindow:) == action) {
		return nil != self.mainViewController.selectedWorkspace && nil != self.mainViewController.view.superview;
	}
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
		session.initialFileSelection = initialFile;
		self.currentSessionController = [[MacSessionViewController alloc] initWithSession:session];
	}
	[self.navController pushViewController:self.currentSessionController animated:YES];
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
	[self openSession:self.mainViewController.selectedWorkspace inNewWindow:NO];
}

-(IBAction)doOpenSessionInNewWindow:(id)sender
{
	[self openSession:self.mainViewController.selectedWorkspace inNewWindow:YES];
}


/*
-(IBAction)doMoveSessionToNewWindow:(id)sender
{
	id selItem = [self targetSessionListObjectForUIItem:sender];
	if (nil == selItem)
		selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	ZAssert([selItem isKindOfClass:[RCSession class]], @"invalid object passed to moveSessionToNewWindow:%@", 
			NSStringFromClass([selItem class]));
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	MacSessionViewController *svc = [appDel viewControllerForSession:selItem create:NO];
	if (self.detailView == svc.view) {
		self.detailView=nil;
		[self.mainSourceList selectRowIndexes:nil byExtendingSelection:NO];
	}
	SessionWindowController *swc = [[SessionWindowController alloc] initWithViewController:svc];
	[swc.window makeKeyAndOrderFront:self];
}
*/

#pragma mark - accessors & synthesizers

@synthesize kvoObservers;
@synthesize mainViewController;
@synthesize detailContainer;
@synthesize detailController;
@synthesize currentSessionController;
@synthesize addToolbarMenu;
@synthesize navController;
@end
