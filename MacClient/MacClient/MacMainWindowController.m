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
#import "WorkspaceViewController.h"
#import <Vyana/NSMenu+AMExtensions.h>

@interface MacMainWindowController()
@property (strong) NSMutableDictionary *workspacesItem;
@property (strong) NSMutableDictionary *sessionsItem;
@property (strong) NSMutableArray *kvoObservers;
@property (strong) NSMutableDictionary *wspaceControllers;
@end

#pragma mark -

@implementation MacMainWindowController

#pragma mark - init/load

- (id)init
{
	if ((self = [super initWithWindowNibName:@"MacMainWindow"])) {
		self.workspacesItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"WORKSPACES", @"name", nil];
		self.sessionsItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"SESSIONS", @"name", nil];
		self.wspaceControllers = [[NSMutableDictionary alloc] init];
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
	__weak MacMainWindowController *blockRef = self;
	[self.kvoObservers addObject:[AMKeyValueObserver observerWithObject:[Rc2Server sharedInstance] keyPath:@"workspaceItems" withOptions:0 
				observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
	{
		[blockRef.mainSourceList reloadData];
	}]];
	[self.kvoObservers addObject:[AMKeyValueObserver observerWithObject:[NSApp delegate] keyPath:@"openSessions" withOptions:0 
				observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
	{
	  [blockRef.mainSourceList reloadItem:blockRef.sessionsItem];
	}]];
	[self.mainSourceList reloadData];
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	BOOL fromContextMenu = NO;
	id selItem = [self.mainSourceList itemAtRow:[self.mainSourceList selectedRow]];
	id menuItem = item;
	if ([menuItem isKindOfClass:[NSMenuItem class]]) {
		//we want to enable right clicking on an unselected object. this is how we tell if that is what is happening
		id repObj = [[menuItem menu] representedObject];
		//just in case the we ever put these menu items in the menu bar or somewhere else
		if ([repObj isKindOfClass:[RCWorkspaceItem class]] || repObj == self.workspacesItem) {
			selItem = repObj;
			fromContextMenu=YES;
		}
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
	if (fromContextMenu)
		return NO;
	return YES;
}

#pragma mark - actions

-(IBAction)doNewWorksheetFolder:(id)sender
{
	
}

-(IBAction)doRenameWorksheetFolder:(id)sender
{
	
}

-(IBAction)doOpenSession:(id)sender
{
	
}

-(IBAction)doOpenSessionInNewWindow:(id)sender
{
	
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
		[self.detailView removeAllSubviews];
		[self.detailView addSubview:rvc.view];
	} else {
		[self.detailView removeAllSubviews];
	}
}

-(NSUInteger)sourceList:(PXSourceList *)sourceList numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return 2;
	if (item == self.workspacesItem)
		return [[Rc2Server sharedInstance].workspaceItems count];
	if ([item isFolder])
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
	return [item isKindOfClass:[NSDictionary class]];
}

-(BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group
{
	if (group == self.workspacesItem)
		return YES;
	return NO;
}

- (NSMenu*)sourceList:(PXSourceList*)aSourceList menuForEvent:(NSEvent*)theEvent item:(id)item
{
	NSMenu *menu=nil;
	if ([item isKindOfClass:[RCWorkspace class]])
		menu = [self.wsheetContextMenu copy];
	else if ([item isKindOfClass:[RCWorkspaceFolder class]] || item == self.workspacesItem)
		menu = self.wsheetFolderContextMenu;
	menu.representedObject = item;
	return menu;
}

#pragma mark -synthesizers

@synthesize mainSourceList;
@synthesize detailView;
@synthesize wsheetContextMenu;
@synthesize wsheetFolderContextMenu;
@synthesize kvoObservers;
@synthesize wspaceControllers;
@synthesize workspacesItem;
@synthesize sessionsItem;
@end
