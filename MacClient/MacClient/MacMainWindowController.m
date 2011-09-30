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

@interface MacMainWindowController()
@property (strong) NSMutableDictionary *workspacesItem;
@property (strong) id wsitemObserver;
@property (strong) NSMutableDictionary *wspaceControllers;
@end

@implementation MacMainWindowController
@synthesize mainSourceList=_mainSourceList;
@synthesize workspacesItem=_workspacesItem;
@synthesize wsitemObserver;
@synthesize wspaceControllers;
- (id)init
{
	if ((self = [super initWithWindowNibName:@"MacMainWindow"])) {
		self.workspacesItem = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"WORKSPACES", @"name", nil];
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
	id obs = [AMKeyValueObserver observerWithObject:[Rc2Server sharedInstance] keyPath:@"workspaceItems" withOptions:0 
				observerBlock:^(id obj, NSString *keyPath, NSDictionary *change)
	{
		[self.mainSourceList reloadData];
	}];
	self.wsitemObserver = obs;
	[self.mainSourceList reloadData];
//	[self.mainSourceList expandItem:self.workspacesItem expandChildren:NO];
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
		return 1;
	if (item == self.workspacesItem)
		return [[Rc2Server sharedInstance].workspaceItems count];
	if ([item isFolder])
		return [[item children] count];
	return 0;
}

-(id)sourceList:(PXSourceList *)aSourceList child:(NSUInteger)index ofItem:(id)item
{
	if (nil == item)
		return self.workspacesItem;
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

@synthesize detailView;
@end
