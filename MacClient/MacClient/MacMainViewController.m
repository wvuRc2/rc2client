//
//  MacMainViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacMainViewController.h"
#import "Rc2Server.h"
#import "RCWorkspaceFolder.h"
#import "RCWorkspace.h"
#import "RCSession.h"
#import "WorkspaceViewController.h"
#import <Vyana/NSMenu+AMExtensions.h>
#import "MacMainWindowController.h"
#import "RCMacToolbarItem.h"
#import "RCMAppConstants.h"

#define kControllerClass @"controllerClass"
#define kLastSelectedPathKey @"MainViewLastSelectedSrcItem"

@interface MacMainViewController() {
	BOOL __didInit;
	BOOL __observingWindowClose;
	BOOL __setupAddMenu;
}
@property (nonatomic, strong) id curPromptController;
@property (strong) NSArray *rootItems;
@property (strong) NSMutableDictionary *workspacesItem;
@property (strong) NSMutableDictionary *adminItem;
@property (strong) NSMutableArray *kvoObservers;
@property (strong) NSMutableDictionary *wspaceControllers;
-(void)openSession:(id)sender inNewWindow:(BOOL)inNewWindow;
-(void)showSourceItem:(NSDictionary*)dict;
-(void)windowAboutToClose:(NSNotification*)note;
@end

@implementation MacMainViewController
@synthesize detailView=__detailView;

- (id)init
{
	if (([super initWithNibName:@"MacMainViewController" bundle:nil])) {
		self.workspacesItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"WORKSPACES", @"name", nil];
		self.adminItem = [NSMutableDictionary dictionaryWithObject:@"ADMIN" forKey:@"name"];
		NSArray *adminItems = ARRAY([NSMutableDictionary dictionaryWithObjectsAndKeys:@"users", @"name",
							   @"RCMUserAdminController", kControllerClass, nil],
									[NSMutableDictionary dictionaryWithObjectsAndKeys:@"permissions", @"name",
									 @"RCMRolePermController", kControllerClass, nil]);
		[self.adminItem setObject:adminItems forKey:@"children"];
		self.wspaceControllers = [[NSMutableDictionary alloc] init];
		self.kvoObservers = [NSMutableArray array];
	}
	return self;
}

-(void)awakeFromNib
{
	if (!__didInit) {
		if ([[Rc2Server sharedInstance] isAdmin])
			self.rootItems = ARRAY(self.workspacesItem, self.adminItem);
		else
			self.rootItems = [NSArray arrayWithObject:self.workspacesItem];
		__unsafe_unretained MacMainViewController *blockRef = self;
		[self.kvoObservers addObject:[AMKeyValueObserver observerWithObject:[Rc2Server sharedInstance] keyPath:@"workspaceItems" withOptions:0 
					observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
		{
			[blockRef.mainSourceList reloadData];
		}]];
		[self.mainSourceList reloadData]; 
		//reload the last selected path
		NSIndexPath *lastPath = [[NSUserDefaults standardUserDefaults] unarchiveObjectForKey:kLastSelectedPathKey];
		[self.mainSourceList selectItemAtIndexPath:lastPath];
		for (NSMenuItem *mi in self.addMenu.itemArray)
			mi.target = self;
		__didInit=YES;
	}
}

-(void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (!__setupAddMenu) {
		NSToolbar *tbar = [NSApp valueForKeyPath:@"delegate.mainWindowController.window.toolbar"];
		RCMacToolbarItem *ti = [tbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
		if (newSuperview)
			[ti pushActionMenu:self.addMenu];
		__setupAddMenu=YES;
	}
}

-(void)viewDidMoveToWindow
{
	if (self.view.window && !__observingWindowClose) {
		//we want to register for when the window closes so we can save state
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowAboutToClose:) 
													 name:NSWindowWillCloseNotification 
												   object:self.view.window];
		__observingWindowClose=YES;
	}
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
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
		if ([selItem isKindOfClass:[RCWorkspace class]] && nil != self.view.superview) 
			return YES;
		return NO;
	}
	if (@selector(doRefreshFileList:) == action) {
		if ([selItem isKindOfClass:[RCWorkspace class]])
			return YES;
		return NO;
	}
	if (@selector(doAddWorkspace:) == action) {
		NSLog(@"oking add workspace");
		return YES;
	}
	return YES;
}

#pragma mark - actions

-(IBAction)doAddWorkspace:(id)sender
{
	[self promptToAddWorkspace:NO];
}

-(IBAction)doAddWorkspaceFolder:(id)sender
{
	[self promptToAddWorkspace:YES];
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

-(IBAction)doRefreshFileList:(id)sender
{
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	if ([selItem respondsToSelector:@selector(doRefreshFileList:)])
		[selItem doRefreshFileList:sender];
}

-(IBAction)sourceListDoubleClicked:(id)sender
{
	//FIXME: need to handle if an item is not selected
	RunAfterDelay(0.5, ^{
		[self doOpenSession:sender];
	});
}

#pragma mark - admin

-(void)showSourceItem:(NSMutableDictionary*)dict
{
	MacClientAbstractViewController *controller = [dict objectForKey:@"controller"];
	if (nil == controller) {
		Class cl = NSClassFromString([dict objectForKey:kControllerClass]);
		controller = [[cl alloc] init];
		[dict setObject:controller forKey:@"controller"];
	}
	self.detailView = (AMControlledView*)controller.view;
}

#pragma mark - meat & potatos

-(void)promptToAddWorkspace:(BOOL)isFolder
{
	RCWorkspaceItem *selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	//prompt for workspace name
	AMStringPromptWindowController *pwc = [[AMStringPromptWindowController alloc] init];
	__unsafe_unretained AMStringPromptWindowController *blockPwc = pwc;
	self.curPromptController=pwc;
	pwc.promptString = isFolder ? @"Folder Name:" : @"Workspace Name:";
	pwc.okButtonTitle = @"Create";
	[pwc displayModelForWindow:self.view.window completionHandler:^(NSInteger rc) {
		if (rc == NSOKButton) {
			NSString *strVal = blockPwc.stringValue;
			self.curPromptController=nil;
			//by default, add to parent of selected item
			RCWorkspaceFolder *folder = (RCWorkspaceFolder*)[selItem parentItem];
			//if a folder is selected, add to that folder
			if ([selItem isKindOfClass:[RCWorkspaceFolder class]])
				folder = (RCWorkspaceFolder*)selItem;
			[[Rc2Server sharedInstance] addWorkspace:strVal parent:folder folder:isFolder 
								   completionHandler:^(BOOL success, RCWorkspaceItem *results)
			{
				if (!success)
					Rc2LogError(@"error adding workspace:%@", results);
				//expand all parent items (no matter depth)
				NSMutableArray *parents = [NSMutableArray array];
				RCWorkspaceFolder *parent = (RCWorkspaceFolder*)[results parentItem];
				while (parent) {
					[parents insertObject:parent atIndex:0];
					parent = (RCWorkspaceFolder*)parent.parentItem;
				}
				for (id anItem in parents)
					[self.mainSourceList expandItem:anItem];
				//select row that was added
				NSInteger rowIdx = [self.mainSourceList rowForItem:results];
				if (-1 != rowIdx) {
					[self.mainSourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIdx] byExtendingSelection:NO];
				}
			}];
		}
	}];
	
}

-(void)openSession:(id)sender inNewWindow:(BOOL)inNewWindow
{
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	ZAssert([selItem isKindOfClass:[RCWorkspace class]], @"invalid object passed to openSession:%@", 
			NSStringFromClass([selItem class]));
	RCWorkspace *selWspace = selItem;
	MacMainWindowController *mainwc = [NSApp valueForKeyPath:@"delegate.mainWindowController"];
	[mainwc openSession:selWspace inNewWindow:inNewWindow];
}

-(void)windowAboutToClose:(NSNotification*)note
{
	//save the selected index path to user defaults
	NSIndexPath *path = [self.mainSourceList indexPathForSelectedItem];
	[[NSUserDefaults standardUserDefaults] archiveObject:path forKey:kLastSelectedPathKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - source list

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
	} else if ([selItem isKindOfClass:[NSDictionary class]] && [selItem objectForKey:kControllerClass]) {
		[self showSourceItem:selItem];
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
	if (item == self.adminItem)
		return [[self.adminItem objectForKey:@"children"] count];
	if ([item respondsToSelector:@selector(isFolder)] && [item isFolder])
		return [[item children] count];
	return 0;
}

-(id)sourceList:(PXSourceList *)aSourceList child:(NSUInteger)index ofItem:(id)item
{
	if (nil == item) {
		if (index == 1)
			return self.adminItem;
		return self.workspacesItem;
	}
	if (item == self.workspacesItem)
		return [[Rc2Server sharedInstance].workspaceItems objectAtIndexNoExceptions:index];
	if (item == self.adminItem)
		return [[self.adminItem objectForKey:@"children"] objectAtIndexNoExceptions:index];
	if ([item isKindOfClass:[RCWorkspaceFolder class]])
		return [[item children] objectAtIndexNoExceptions:index];
	return nil;
}

-(id)sourceList:(PXSourceList *)aSourceList objectValueForItem:(id)item
{
	if ([item isKindOfClass:[NSDictionary class]])
		return [item objectForKey:@"name"];
	if ([item isKindOfClass:[RCWorkspaceItem class]])
		return [item name];
	return nil;
}

-(BOOL)sourceList:(PXSourceList *)aSourceList isItemExpandable:(id)item
{
	if ([item isKindOfClass:[RCWorkspaceItem class]])
		return [item isFolder];
	return item == self.workspacesItem || item == self.adminItem;
}

-(BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group
{
	if (group == self.workspacesItem || group == self.adminItem)
		return YES;
	return NO;
}

- (NSMenu*)sourceList:(PXSourceList*)aSourceList menuForEvent:(NSEvent*)theEvent item:(id)item
{
	NSMenu *menu=nil;
//	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	if ([item isKindOfClass:[RCWorkspace class]]) {
/*		RCSession *session = [appDel sessionForWorkspace:item];
		MacSessionViewController *svc = [appDel viewControllerForSession:session create:NO];
		if (svc) {
			if (svc.view.window && svc.view.window != self.window)
				return nil; //it has its own window, no menu for you
		}
*/		menu = [self.wsheetContextMenu copy];
	} else if ([item isKindOfClass:[RCWorkspaceFolder class]] || item == self.workspacesItem) {
		menu = self.wsheetFolderContextMenu;
	}
	menu.representedObject = item;
	return menu;
}

#pragma mark - split view delegate

-(CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (proposedMaximumPosition > 400)
		return 400;
	return proposedMaximumPosition;
}

-(CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (proposedMinimumPosition < 160)
		return 160;
	return proposedMinimumPosition;
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
		[self.detailContainer.animator replaceSubview:__detailView with:aView];
		__detailView = aView;
	}
	aView.frame = self.detailContainer.bounds;
	self.detailController = (MacClientAbstractViewController*)aView.viewController;
}

-(RCWorkspace*)selectedWorkspace
{
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	if ([selItem isKindOfClass:[RCWorkspace class]])
		return selItem;
	return nil;
}

@synthesize mainSourceList;
@synthesize wsheetContextMenu;
@synthesize wsheetFolderContextMenu;
@synthesize kvoObservers;
@synthesize wspaceControllers;
@synthesize workspacesItem;
@synthesize adminItem;
@synthesize detailController;
@synthesize detailContainer;
@synthesize addMenu;
@synthesize rootItems;
@synthesize curPromptController=_curPromptController;
@end
