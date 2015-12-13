//
//  MCProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "MCProjectViewController.h"
#import "Rc2RestServer.h"
#import "MCProjectCollectionView.h"
#import "MCMainWindowController.h"
#import "MCProjectCollectionItem.h"
#import "ThemeEngine.h"
#import "MCAppConstants.h"
#import "MCMainWindowController.h" //for doBackToMainView: selector
#import "MCProjectShareController.h"
#import "Rc2-Swift.h"

@interface MCProjectView : AMControlledView

@end

@interface MCProjectViewController () <ProjectCollectionDelegate,NSPopoverDelegate>
@property (weak) IBOutlet MCProjectCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) RCProject *selectedProject;
@property (strong) MCProjectShareController *currentShareController;
@property (strong) NSPopover *sharePopover;
@end

@implementation MCProjectViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	Rc2RestServer *server = [Rc2RestServer sharedInstance];
	self.arrayController.content = [server.loginSession.workspaces mutableCopy];
	__weak __typeof(self) blockSelf = self;
	[self observeTarget:self.arrayController keyPath:@"selectionIndexes" options:0 block:^(MAKVONotification *notification) {
		[blockSelf willChangeValueForKey:@"canDeleteSelection"];
		[blockSelf didChangeValueForKey:@"canDeleteSelection"];
	}];
	NSNotificationCenter *nc  = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(loginChanged:) name:Rc2RestLoginStatusChangedNotification object:nil];
}

#pragma mark - meat & potatos

-(void)loginChanged:(NSNotification *)note
{
	Rc2RestServer *server = [Rc2RestServer sharedInstance];
	if (server.loginSession) {
		self.arrayController.content = [server.loginSession.workspaces mutableCopy];
	} else {
		self.arrayController.content = @[];
	}
}

-(BOOL)usesToolbar { return YES; }

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"back"];
}

-(BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = anItem.action;
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (action == @selector(renameWorkspace:)) {
		anItem.title = NSLocalizedString(@"RenameWorkspaceMI", @"");
		return YES;
	} else if (action == @selector(createWorkspace:)) {
		anItem.title = NSLocalizedString(@"CreateWorkspaceMI", @"");
		return YES;
	} else if (action == @selector(openWorkspace:)) {
		anItem.title = NSLocalizedString(@"OpenWorkspaceMI", @"");
		return YES;
	}
	return NO;
}

-(BOOL)canDeleteSelection
{
	if (!self.arrayController.canRemove)
		return NO;
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (nil == selObj)
		return NO;
	return YES;
}

-(void)openSessionWithWorkspace:(Rc2Workspace*)wspace
{
	if (nil == wspace)
		wspace = self.arrayController.selectedObjects.firstObject;
	[self.view.window.windowController openSession:wspace file:nil];
}

-(void)displayTopLevel
{
}

#pragma mark - actions

-(IBAction)createWorkspace:(id)sender
{
	AMStringPromptWindowController *pc = [[AMStringPromptWindowController alloc] init];
	pc.promptString = NSLocalizedString(@"Workspace name:", @"");
	pc.okButtonTitle = NSLocalizedString(@"Create", @"");
	pc.validationBlock = ^(AMStringPromptWindowController *pcc) {
		if (pcc.stringValue.length < 1)
			return NO;
		if (nil != [self.arrayController.arrangedObjects firstObjectWithValue:pcc.stringValue forKey:@"name"]) {
			pcc.validationErrorMessage = NSLocalizedString(@"A Workspace with that name already exists", @"");
			return NO;
		}
		return YES;
	};
	self.busy = YES;
	self.statusMessage = NSLocalizedString(@"Creating workspace…", @"");
	[pc displayModelForWindow:self.view.window completionHandler:^(NSInteger rc) {
		self.busy = NO;
		self.statusMessage = nil;
		if (rc == NSOKButton) {
/*			[RC2_SharedInstance() createWorkspace:pc.stringValue inProject:self.selectedProject completionBlock:^(BOOL success, id obj) {
				if (success) {
					NSInteger idx = [self.selectedProject.workspaces indexOfObject:obj];
					[self.arrayController insertObject:obj atArrangedObjectIndex:idx];
				} else {
					//TODO: notify user that failed
					Rc2LogError(@"failed to create project:%@", obj);
				}
			}];
*/		}
	}];
}

-(IBAction)removeSelectedWorkspaces:(id)sender
{
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (![self canDeleteSelection]) {
		NSBeep();
		return;
	}
	NSAlert *alert = [NSAlert alertWithMessageText:@"Confirm Delete?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Are you sure you want to delete workspace \"%@\"? This can not be undone.", [selObj name]];
	[alert am_beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *balert, NSInteger rc) {
		if (NSAlertDefaultReturn == rc) {
/*			[RC2_SharedInstance() deleteWorkspce:selObj completionHandler:^(BOOL success, id results) {
				if (success) {
						[self.arrayController removeObject:selObj];
				[[selObj project] removeWorkspace:selObj];
				} else {
				//TODO: notify user that failed
				Rc2LogError(@"failed to delete workspace:%@", [selObj name]);
				}
			}];
*/		}
	}];
}

-(IBAction)renameWorkspace:(id)sender
{
	id item = [self.collectionView itemAtIndex:self.collectionView.selectionIndexes.firstIndex];
	[item startNameEditing];
}

-(IBAction)openWorkspace:(id)sender
{
	[self openSessionWithWorkspace:nil];
}

#pragma mark - collection view

-(void)replaceItemsWithChildrenOf:(RCProject*)project
{
}

-(void)collectionView:(MCProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item
{
	[self openSessionWithWorkspace:item];
}

-(void)collectionView:(MCProjectCollectionView*)cview deleteBackwards:(id)sender
{
	[self removeSelectedWorkspaces:cview];
}

-(void)collectionView:(MCProjectCollectionView *)cview swipeBackwards:(NSEvent*)event
{
	if (self.selectedProject)
		[self displayTopLevel];
}

-(void)collectionView:(MCProjectCollectionView *)cview renameItem:(MCProjectCollectionItem*)item name:(NSString*)newName
{
	Rc2Workspace *wspace = item.representedObject;
	self.busy = YES;
/*	[RC2_SharedInstance() renameWorkspce:modelObject name:newName completionHandler:^(BOOL success, id arg) {
		if (success) {
			[item reloadItemDetails];
		} else {
			[NSAlert displayAlertWithTitle:@"Error renaming Workspace" details:arg];
		}
		self.busy=NO;
	}];
*/}

-(void)collectionView:(MCProjectCollectionView *)cview showShareInfo:(RCProject*)project fromRect:(NSRect)rect
{
	self.currentShareController = [[MCProjectShareController alloc] init];
	self.currentShareController.project = project;
	self.sharePopover = [[NSPopover alloc] init];
	self.sharePopover.behavior = NSPopoverBehaviorTransient;
	self.sharePopover.contentViewController = self.currentShareController;
	self.sharePopover.delegate = self;
	[self.sharePopover showRelativeToRect:rect ofView:cview preferredEdge:NSMaxXEdge];
}

-(void)popoverDidClose:(NSNotification *)notification
{
	self.currentShareController = nil;
	self.sharePopover = nil;
}

@end

@implementation MCProjectView

//this skanky hack makes no sense. the call to super is not resizing this view. since we always want it to be full size,
// we manually do it
-(void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[super resizeWithOldSuperviewSize:oldSize];
	NSRect f = self.frame;
	f.size = self.superview.frame.size;
	self.frame = f;
}

@end