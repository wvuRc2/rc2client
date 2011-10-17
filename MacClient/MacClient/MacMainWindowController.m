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
#import "RCMSessionWindowController.h"
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
	self.mainViewController = [[MacMainViewController alloc] init];
	self.mainViewController.view.frame = self.detailContainer.frame;
	NSView *contentView = self.window.contentView;
	[contentView replaceSubview:self.detailContainer with:self.mainViewController.view];
	NSToolbar *tbar = [[NSToolbar alloc] initWithIdentifier:@"mainwindow"];
	[tbar setAllowsUserCustomization:NO];
	[tbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[tbar setSizeMode:NSToolbarSizeModeSmall];
	tbar.delegate = [NSApp delegate];
	self.window.toolbar = tbar;
	RCMacToolbarItem *addItem = [tbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
	addItem.actionMenu = self.addToolbarMenu;
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (@selector(doBackToMainView:) == action) {
		if (self.mainViewController.view.superview == nil) return YES;
		return NO;
	} else if (@selector(doOpenSession:) == action || @selector(doOpenSessionInNewWindow:) == action) {
		return nil != self.mainViewController.selectedWorkspace;
	}
	return YES;
}

#pragma mark - meat & potatos

-(void)openSession:(RCWorkspace*)wspace inNewWindow:(BOOL)inNewWindow
{
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	RCSession *session = [appDel sessionForWorkspace:wspace];
	MacSessionViewController *svc = [appDel viewControllerForSession:session create:YES];
	//option key forces new window
	if ([NSEvent modifierFlags] & NSAlternateKeyMask)
		inNewWindow = YES;
	if (inNewWindow && nil == svc.view.superview) {
		RCMSessionWindowController *swc = [[RCMSessionWindowController alloc] initWithViewController:svc];
		[swc.window makeKeyAndOrderFront:self];
	} else {
		self.currentSessionController = svc;
		NSView *contentView = self.window.contentView;
		CATransition *anim = [CATransition animation];
		anim.type = kCATransitionMoveIn;
		anim.subtype = kCATransitionFromRight;
		contentView.animations = [NSDictionary dictionaryWithObject:anim forKey:@"subviews"];
		svc.view.frame = self.mainViewController.view.frame;
		[contentView.animator replaceSubview:self.mainViewController.view with:svc.view];
	}
}

#pragma mark - actions

-(IBAction)doBackToMainView:(id)sender
{
	if (self.currentSessionController) {
		NSView *contentView = self.window.contentView;
		CATransition *anim = [CATransition animation];
		anim.type = kCATransitionMoveIn;
		anim.subtype = kCATransitionFromLeft;
		contentView.animations = [NSDictionary dictionaryWithObject:anim forKey:@"subviews"];
		self.mainViewController.view.frame = self.currentSessionController.view.frame;
		[contentView.animator replaceSubview:self.currentSessionController.view with:self.mainViewController.view];
		self.currentSessionController=nil;
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
@end
