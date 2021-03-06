//
//  MCProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "MCProjectViewController.h"
#import "Rc2Server.h"
#import "RCActiveLogin.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "MCProjectCollectionView.h"
#import "MCMainWindowController.h"
#import "MCProjectCollectionItem.h"
#import "ThemeEngine.h"
#import "MCAppConstants.h"
#import "MCMainWindowController.h" //for doBackToMainView: selector
#import "MCProjectShareController.h"

@interface MCProjectView : AMControlledView

@end

@interface MCProjectViewController () <ProjectCollectionDelegate,NSPopoverDelegate>
@property (weak) IBOutlet MCProjectCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) NSMutableArray *pathCells;
@property (weak) IBOutlet NSPathControl *pathControl;
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
	self.pathCells = [NSMutableArray arrayWithCapacity:4];
	[self.pathCells addObject:[NSPathComponentCell pathCellWithTitle:@"Projects"]];
	[self.pathControl setPathComponentCells:self.pathCells];
	self.arrayController.content = [RC2_SharedInstance().activeLogin.projects mutableCopy];
	__weak __typeof(self) blockSelf = self;
	[self observeTarget:self.arrayController keyPath:@"selectionIndexes" options:0 block:^(MAKVONotification *notification) {
		[blockSelf willChangeValueForKey:@"canDeleteSelection"];
		[blockSelf didChangeValueForKey:@"canDeleteSelection"];
	}];
	[self observeTarget:RC2_SharedInstance() keyPath:@"activeLogin" options:0 block:^(MAKVONotification *notification) {
		if (RC2_SharedInstance().activeLogin) {
			[blockSelf observeTarget:RC2_SharedInstance().activeLogin keyPath:@"projects" options:0 block:^(MAKVONotification *notification) {
				[blockSelf updateProjects];
			}];
			[blockSelf updateProjects];
		}
	}];
}

#pragma mark - meat & potatos

-(void)updateProjects
{
	self.arrayController.content = [RC2_SharedInstance().activeLogin.projects mutableCopy];
}

-(BOOL)usesToolbar { return YES; }

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"back"];
}

-(NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [super toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
	if (item.action == @selector(doBackToMainView:)) {
		AMMacToolbarItem *titem = (AMMacToolbarItem*)item;
		titem.validationBlock = ^(AMMacToolbarItem *bitem) {
			[bitem setEnabled:!self.showingProjects];
		};
	}
	return item;
}

-(BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = anItem.action;
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (action == @selector(renameProject:)) {
		NSString *dtitle = self.selectedProject ? @"RenameWorkspaceMI" : @"RenameProjectMI";
		anItem.title = NSLocalizedString(dtitle, @"");
		return [selObj userEditable];
	} else if (action == @selector(createProject:)) {
		NSString *cptitle = self.selectedProject ? @"CreateWorkspaceMI" : @"CreateProjectMI";
		anItem.title = NSLocalizedString(cptitle, @"");
		return YES;
	} else if (action == @selector(openProject:)) {
		NSString *otitle = self.selectedProject ? @"OpenWorkspaceMI" : @"OpenProjectMI";
		anItem.title = NSLocalizedString(otitle, @"");
		return selObj != nil;
	}
	return NO;
}

-(BOOL)showingProjects
{
	return self.pathCells.count == 1;
}

-(BOOL)canDeleteSelection
{
	if (!self.arrayController.canRemove)
		return NO;
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (nil == selObj)
		return NO;
	if ([selObj isKindOfClass:[RCProject class]] & ![selObj userEditable])
		return NO;
	return YES;
}

-(void)openItem:(id)item
{
	if (nil == item)
		item = self.arrayController.selectedObjects.firstObject;
	if ([item isKindOfClass:[RCWorkspace class]]) {
		[self.view.window.windowController openSession:item file:nil inNewWindow:NO];
		return;
	}
	if ([item isKindOfClass:[RCProject class]]) {
		if ([[(RCProject*)item type] isEqualToString:@"admin"]) {
			[self.view.window.windowController showAdminTools:self];
			return;
		}
		if ([[item workspaces] count] < 1)
			return; //nothing to do
	}
	NSRect centerRect = [_collectionView frameForItemAtIndex:0];
	NSSize viewSize = self.view.frame.size;
	centerRect.origin.x = floorf((viewSize.width - centerRect.size.width) / 2);
	centerRect.origin.y = floorf((viewSize.height - centerRect.size.height) / 2);
	[NSAnimationContext beginGrouping];
	[NSAnimationContext currentContext].duration = 0.4;
	for (NSInteger i=0; i < [self.arrayController.arrangedObjects count]; i++) {
		NSCollectionViewItem *item = [_collectionView itemAtIndex:i];
		[item.view.animator setFrame:centerRect];
	}
	[NSAnimationContext currentContext].completionHandler = ^{
		[self replaceItemsWithChildrenOf:item];
	};
	[NSAnimationContext endGrouping];
	self.selectedProject = item;
	[self.view.window.toolbar validateVisibleItems];
}

-(void)displayTopLevel
{
	[self.pathCells removeAllObjects];
	[self.pathCells addObject:[NSPathComponentCell pathCellWithTitle:@"Project"]];
	[self.pathControl setPathComponentCells:self.pathCells];
	[self updateProjects];
	dispatch_async(dispatch_get_main_queue(), ^{
		NSPathComponentCell *cell = self.pathCells.firstObject;
		[cell setState:NSOffState];
		[self.collectionView setNeedsDisplay:YES];
	});
	self.selectedProject=nil;
	[self.view.window.toolbar validateVisibleItems];
}

#pragma mark - actions

-(IBAction)pathControlClicked:(id)sender
{
	NSUInteger idx = [self.pathCells indexOfObject:[self.pathControl clickedPathComponentCell]];
	ZAssert(idx != NSNotFound, @"impossible cell clicked");
	[self.pathControl.clickedPathComponentCell setState:NSOffState];
	if (idx+1 == self.pathCells.count)
		return; //clicked the current level
	if (idx == 0) {
		[self displayTopLevel];
	} else {
		ZAssert(NO, @"not implemented");
	}
}

-(IBAction)createProject:(id)sender
{
	BOOL isProj = [self showingProjects];
	NSString *objType = isProj ? @"Project" : @"Workspace";
	AMStringPromptWindowController *pc = [[AMStringPromptWindowController alloc] init];
	pc.promptString = [NSString stringWithFormat:@"%@ name:", objType];
	pc.okButtonTitle = @"Create";
	pc.validationBlock = ^(AMStringPromptWindowController *pcc) {
		if (pcc.stringValue.length < 1)
			return NO;
		if (nil != [self.arrayController.arrangedObjects firstObjectWithValue:pcc.stringValue forKey:@"name"]) {
			pcc.validationErrorMessage = [NSString stringWithFormat:@"A %@ with that name already exists", objType];
			return NO;
		}
		return YES;
	};
	self.busy = YES;
	self.statusMessage = [NSString stringWithFormat:@"Creating %@", objType];
	[pc displayModelForWindow:self.view.window completionHandler:^(NSInteger rc) {
		self.busy = NO;
		self.statusMessage = nil;
		if (rc == NSOKButton) {
			if (isProj) {
				[RC2_SharedInstance() createProject:pc.stringValue completionBlock:^(BOOL success, id obj) {
					if (success) {
						//NSInteger idx = [RC2_SharedInstance().projects indexOfObject:obj];
					//			[self.arrayController insertObject:obj atArrangedObjectIndex:idx];
					} else {
						//TODO: notify user that failed
						Rc2LogError(@"failed to create project:%@", obj);
					}
				}];
			} else {
				[RC2_SharedInstance() createWorkspace:pc.stringValue inProject:self.selectedProject completionBlock:^(BOOL success, id obj) {
					if (success) {
						NSInteger idx = [self.selectedProject.workspaces indexOfObject:obj];
						[self.arrayController insertObject:obj atArrangedObjectIndex:idx];
					} else {
						//TODO: notify user that failed
						Rc2LogError(@"failed to create project:%@", obj);
					}
				}];
			}
		}
	}];
}

-(IBAction)removeSelectedProjects:(id)sender
{
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (![self canDeleteSelection]) {
		NSBeep();
		return;
	}
	NSAlert *alert = [NSAlert alertWithMessageText:@"Confirm Delete?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Are you sure you want to delete %@ \"%@\"? This can not be undone.", [selObj isKindOfClass:[RCProject class]] ? @"project" : @"workspace", [selObj name]];
	[alert am_beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *balert, NSInteger rc) {
		if (NSAlertDefaultReturn == rc) {
			if ([selObj isKindOfClass:[RCProject class]]) {
				[RC2_SharedInstance() deleteProject:selObj completionBlock:^(BOOL success, id obj) {
					if (success) {
						[self.arrayController removeObject:selObj];
					} else {
						//TODO: notify user that failed
						Rc2LogError(@"failed to delete project:%@", obj);
					}
				}];
			} else {
				//handle workspace
				[RC2_SharedInstance() deleteWorkspce:selObj completionHandler:^(BOOL success, id results) {
					if (success) {
							[self.arrayController removeObject:selObj];
					[[selObj project] removeWorkspace:selObj];
					} else {
					//TODO: notify user that failed
					Rc2LogError(@"failed to delete workspace:%@", [selObj name]);
					}
				}];
			}
		}
	}];
}

-(IBAction)renameProject:(id)sender
{
	id item = [self.collectionView itemAtIndex:self.collectionView.selectionIndexes.firstIndex];
	[item startNameEditing];
}

-(IBAction)openProject:(id)sender
{
	[self openItem:nil];
}

#pragma mark path control delegate

#pragma mark - collection view

-(void)replaceItemsWithChildrenOf:(RCProject*)project
{
	[self.pathCells addObject:[NSPathComponentCell pathCellWithTitle:project.name]];
	[self.pathControl setPathComponentCells:self.pathCells];
	[self.arrayController removeObjects:self.arrayController.arrangedObjects];
	if (project.workspaces.count > 0)
		[self.arrayController addObjects:project.workspaces];
}

-(void)collectionView:(MCProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item
{
	[self openItem:item];
}

-(void)collectionView:(MCProjectCollectionView*)cview deleteBackwards:(id)sender
{
	[self removeSelectedProjects:cview];
}

-(void)collectionView:(MCProjectCollectionView *)cview swipeBackwards:(NSEvent*)event
{
	if (self.selectedProject)
		[self displayTopLevel];
}

-(void)collectionView:(MCProjectCollectionView *)cview renameItem:(MCProjectCollectionItem*)item name:(NSString*)newName
{
	id modelObject = item.representedObject;
	self.busy = YES;
	if ([modelObject isKindOfClass:[RCProject class]]) {
		ZAssert([modelObject userEditable], @"renaming uneditable project");
		[RC2_SharedInstance() editProject:modelObject newName:newName completionBlock:^(BOOL success, id arg) {
			if (!success) {
				[NSAlert displayAlertWithTitle:@"Error renaming project" details:arg];
				[item reloadItemDetails];
			}
			self.busy = NO;
		}];
	} else if ([modelObject isKindOfClass:[RCWorkspace class]]) {
		ZAssert([modelObject userEditable], @"renaming uneditable workspace");
		[RC2_SharedInstance() renameWorkspce:modelObject name:newName completionHandler:^(BOOL success, id arg) {
			if (success) {
				[item reloadItemDetails];
			} else {
				[NSAlert displayAlertWithTitle:@"Error renaming Workspace" details:arg];
			}
			self.busy=NO;
		}];
	}
}

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