//
//  MacMainWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacMainWindowController.h"
#import "Rc2Server.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCSession.h"
#import "WorkspaceViewController.h"
#import <Vyana/NSMenu+AMExtensions.h>
#import "MacSessionViewController.h"
#import "SessionWindowController.h"
#import "AppDelegate.h"

@interface MacMainWindowController()
@property (strong) NSMutableDictionary *workspacesItem;
@property (strong) NSMutableDictionary *sessionsItem;
@property (strong) NSMutableArray *kvoObservers;
@property (strong) NSMutableDictionary *wspaceControllers;
-(void)openSession:(id)sender inNewWindow:(BOOL)inNewWindow;
-(id)targetSessionListObjectForUIItem:(id)item;
@end

#pragma mark -

@implementation MacMainWindowController
@synthesize detailView=__detailView;

#pragma mark - init/load

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MacMainWindow"])) {
		self.workspacesItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"WORKSPACES", @"name", nil];
		self.sessionsItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"SESSIONS", @"name", nil];
		self.wspaceControllers = [[NSMutableDictionary alloc] init];
		self.kvoObservers = [NSMutableArray array];
		self.canAdd=YES;
	}
	return self;
}

-(void)dealloc
{
	NSLog(@"window gone");
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	__unsafe_unretained MacMainWindowController *blockRef = self;
	[self.kvoObservers addObject:[AMKeyValueObserver observerWithObject:[Rc2Server sharedInstance] keyPath:@"workspaceItems" withOptions:0 
				observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
	{
		[blockRef.mainSourceList reloadData];
	}]];
	[self.kvoObservers addObject:[AMKeyValueObserver observerWithObject:[NSApp delegate] keyPath:@"openSessions" withOptions:0 
				observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
	{
	  [blockRef.mainSourceList reloadItem:blockRef.sessionsItem reloadChildren:YES];
	}]];
	[self.mainSourceList reloadData]; 
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	BOOL fromContextMenu = NO;
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	id slobject = [self targetSessionListObjectForUIItem:item];
	if (slobject) {
		selItem = slobject;
		fromContextMenu = YES;
	}
	if (@selector(doRenameWorksheetFolder:) == action) {
		if ([selItem isKindOfClass:[RCWorkspaceFolder class]]) return YES;
		return NO;
	}
	if (@selector(doNewWorksheetFolder:) == action) {
		if (selItem == self.workspacesItem) return YES;
		if ([selItem isKindOfClass:[RCWorkspaceItem class]]) return YES;
		return NO;
	}
	if (@selector(doOpenSession:) == action || @selector(doOpenSessionInNewWindow:) == action) {
		if ([selItem isKindOfClass:[RCWorkspace class]]) return YES;
		return NO;
	}
	if (@selector(doRefreshFileList:) == action) {
		if ([selItem isKindOfClass:[RCWorkspace class]])
			return YES;
		return NO;
	}
	if (fromContextMenu)
		return NO;
	return YES;
}

-(BOOL)windowShouldClose:(id)sender
{
	if ([self.detailView isKindOfClass:[SessionView class]]) {
		MacSessionViewController *svc = (MacSessionViewController*)((AMControlledView*)self.detailView).viewController;
		//we want to close the session
		self.detailView=nil;
		[((AppDelegate*)[NSApp delegate]) closeSessionViewController:svc];
		[self.mainSourceList reloadItem:self.sessionsItem reloadChildren:YES];
		return NO;
	} else if (self.detailView) {
		self.detailView=nil;
		return NO;
	}
	return YES;
}

#pragma mark - meat & potatos

-(id)targetSessionListObjectForUIItem:(id)item
{
	id selItem = nil;
	id menuItem = item;
	if ([menuItem isKindOfClass:[NSMenuItem class]]) {
		//we want to enable right clicking on an unselected object. this is how we tell if that is what is happening
		id repObj = [[menuItem menu] representedObject];
		//just in case the we ever put these menu items in the menu bar or somewhere else
		if ([repObj isKindOfClass:[RCWorkspaceItem class]] || repObj == self.workspacesItem) {
			selItem = repObj;
		}
	}
	return selItem;
}

-(void)openSession:(id)sender inNewWindow:(BOOL)inNewWindow
{
	id selItem = [self targetSessionListObjectForUIItem:sender];
	if (nil == selItem)
		selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	ZAssert([selItem isKindOfClass:[RCWorkspace class]], @"invalid object passed to openSession:%@", 
			NSStringFromClass([selItem class]));
	RCWorkspace *selWspace = selItem;
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	RCSession *session = [appDel sessionForWorkspace:selWspace];
	MacSessionViewController *svc = [appDel viewControllerForSession:session create:YES];
	if (inNewWindow && nil == svc.view.superview) {
		SessionWindowController *swc = [[SessionWindowController alloc] initWithViewController:svc];
		[swc.window makeKeyAndOrderFront:self];
		[self.mainSourceList reloadItem:self.sessionsItem reloadChildren:YES];
	} else {
		self.detailView = (AMControlledView*)svc.view;
		[self.mainSourceList reloadItem:self.sessionsItem reloadChildren:YES];
		[self.mainSourceList amSelectRow:[self.mainSourceList rowForItem:session] byExtendingSelection:NO];
	}
}

#pragma mark - actions

-(IBAction)doRefreshFileList:(id)sender
{
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	if ([selItem respondsToSelector:@selector(doRefreshFileList:)])
		[selItem doRefreshFileList:sender];
}

-(IBAction)doAddWorkspace:(id)sender
{
}

-(IBAction)doAddWorkspaceFolder:(id)sender
{
}

-(IBAction)doRenameWorksheetFolder:(id)sender
{
	
}

-(IBAction)doOpenSession:(id)sender
{
	[self openSession:sender inNewWindow:NO];
}

-(IBAction)doOpenSessionInNewWindow:(id)sender
{
	[self openSession:sender inNewWindow:YES];
}

-(void)doCloseSession:(id)sender
{
	
}

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

#pragma mark - source list

-(NSIndexSet*)sourceList:(PXSourceList *)aSourceList selectionIndexesForProposedSelection:(NSIndexSet *)iset
{
	id item=nil;
	if ([iset count] == 1)
		item = [self.mainSourceList itemAtRow:[iset firstIndex]];
	if ([item isKindOfClass:[RCSession class]]) {
		MacSessionViewController *svc = [((AppDelegate*)[NSApp delegate]) viewControllerForSession:item create:YES];
		if (svc.view.window) {
			//bring it's window to the front
			[svc.view.window makeKeyAndOrderFront:self];
			return nil;
		}
	}
	return iset;
}

-(void)sourceListSelectionDidChange:(NSNotification *)notification
{
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	if ([selItem isKindOfClass:[RCWorkspace class]]) {
		RCWorkspace *selWspace = selItem;
		WorkspaceViewController *rvc = [self.wspaceControllers objectForKey:selWspace.wspaceId];
		if (nil == rvc) {
			//need to load one
			rvc = [[WorkspaceViewController alloc] initWithWorkspace:selWspace];
			[self.wspaceControllers setObject:rvc forKey:selWspace.wspaceId];
		}
		self.detailView = (AMControlledView*)rvc.view;
	} else if ([selItem isKindOfClass:[RCSession class]]) {
		MacSessionViewController *svc = [((AppDelegate*)[NSApp delegate]) viewControllerForSession:selItem create:YES];
		if (nil == svc.view.superview) {
			self.detailView = (AMControlledView*)svc.view;
		} else if (svc.view.window) {
			//bring it's window to the front
			[svc.view.window makeKeyAndOrderFront:self];
		} else {
			//TODO: make multiple windows work
			//if not currently displayed, must be in another window
			ZAssert(svc.view.superview == self.detailContainer, @"incorrect superview");
		}
	} else {
		self.detailView=nil;
	}
}

-(NSUInteger)sourceList:(PXSourceList *)sourceList numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return 2;
	if (item == self.workspacesItem)
		return [[Rc2Server sharedInstance].workspaceItems count];
	if (item == self.sessionsItem) {
		NSArray *sessions = [NSApp valueForKeyPath:@"delegate.openSessions"];
		return [sessions count];
	}
	if ([item respondsToSelector:@selector(isFolder)] && [item isFolder])
		return [[item children] count];
	return 0;
}

-(id)sourceList:(PXSourceList *)aSourceList child:(NSUInteger)index ofItem:(id)item
{
	if (nil == item) {
		if (index == 1)
			return self.sessionsItem;
		return self.workspacesItem;
	}
	if (item == self.workspacesItem)
		return [[Rc2Server sharedInstance].workspaceItems objectAtIndex:index];
	if ([item isKindOfClass:[RCWorkspaceFolder class]])
		return [[item children] objectAtIndex:index];
	if (item == self.sessionsItem)
		return [[NSApp valueForKeyPath:@"delegate.openSessions"] objectAtIndex:index];
	return nil;
}

-(id)sourceList:(PXSourceList *)aSourceList objectValueForItem:(id)item
{
	if ([item isKindOfClass:[NSDictionary class]])
		return [item objectForKey:@"name"];
	if ([item isKindOfClass:[RCWorkspaceItem class]])
		return [item name];
	if ([item isKindOfClass:[RCSession class]])
		return [[item workspace] name];
	return nil;
}

-(BOOL)sourceList:(PXSourceList *)aSourceList isItemExpandable:(id)item
{
	if ([item isKindOfClass:[RCWorkspaceItem class]])
		return [item isFolder];
	return [item isKindOfClass:[NSDictionary class]];
}

-(BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group
{
	if (group == self.workspacesItem)
		return YES;
	if (group == self.sessionsItem)
		return YES;
	return NO;
}

- (NSMenu*)sourceList:(PXSourceList*)aSourceList menuForEvent:(NSEvent*)theEvent item:(id)item
{
	NSMenu *menu=nil;
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	if ([item isKindOfClass:[RCWorkspace class]]) {
		RCSession *session = [appDel sessionForWorkspace:item];
		MacSessionViewController *svc = [appDel viewControllerForSession:session create:NO];
		if (svc) {
			if (svc.view.window && svc.view.window != self.window)
				return nil; //it has its own window, no menu for you
		}
		menu = [self.wsheetContextMenu copy];
	} else if ([item isKindOfClass:[RCWorkspaceFolder class]] || item == self.workspacesItem) {
		menu = self.wsheetFolderContextMenu;
	} else if ([item isKindOfClass:[RCSession class]]) {
		menu = self.sessionContextMenu;
	}
	menu.representedObject = item;
	return menu;
}

#pragma mark - accessors & synthesizers

-(void)setDetailView:(AMControlledView *)aView
{
	if (__detailView == aView)
		return;
	if (__detailView == nil) {
		__detailView = aView;
		[self.detailContainer addSubview:aView];
	} else if (aView == nil) {
		[__detailView removeFromSuperview];
		__detailView = nil;
	} else {
		[aView setFrameSize:self.detailContainer.contentSize];
		[self.detailContainer.animator replaceSubview:__detailView with:aView];
		__detailView = aView;
	}
	self.detailController = (MacClientAbstractViewController*)aView.viewController;
}

@synthesize mainSourceList;
@synthesize wsheetContextMenu;
@synthesize wsheetFolderContextMenu;
@synthesize sessionContextMenu;
@synthesize kvoObservers;
@synthesize wspaceControllers;
@synthesize workspacesItem;
@synthesize sessionsItem;
@synthesize canAdd;
@synthesize addPopup;
@synthesize detailContainer;
@synthesize detailController;
@end
