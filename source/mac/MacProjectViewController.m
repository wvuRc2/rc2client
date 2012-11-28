//
//  MacProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/25/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "MacProjectViewController.h"
#import "Rc2Server.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "MacProjectCollectionView.h"
#import "MacMainWindowController.h"
#import "MacProjectCollectionItem.h"

@interface MacProjectViewController () <ProjectCollectionDelegate>
@property (weak) IBOutlet MacProjectCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) NSMutableArray *pathCells;
@property (weak) IBOutlet NSPathControl *pathControl;
@property (strong) RCProject *selectedProject;
@end

@implementation MacProjectViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.pathCells = [NSMutableArray arrayWithCapacity:4];
	[self.pathCells addObject:[self pathCellWithTitle:@"Projects"]];
	[self.pathControl setPathComponentCells:self.pathCells];
	self.arrayController.content = [[[Rc2Server sharedInstance] projects] mutableCopy];
	__weak __typeof(self) blockSelf = self;
	[self.arrayController addObserverForKeyPath:@"selectionIndexes" task:^(id obj, NSDictionary *change) {
		[blockSelf willChangeValueForKey:@"canDeleteSelection"];
		[blockSelf didChangeValueForKey:@"canDeleteSelection"];
	}];
}

#pragma mark - meat & potatos

-(BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = anItem.action;
	id selObj = self.arrayController.selectedObjects.firstObject;
	if (action == @selector(renameProject:)) {
		NSString *dtitle = self.selectedProject ? @"RenameWorkspaceMI" : @"RenameProjectMI";
		anItem.title = NSLocalizedString(dtitle, @"");
		return [selObj canDelete];
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

-(NSPathComponentCell*)pathCellWithTitle:(NSString*)title
{
	NSPathComponentCell *cell = [[NSPathComponentCell alloc] init];
	cell.title = title;
	return cell;
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
	if ([selObj isKindOfClass:[RCProject class]] & ![selObj canDelete])
		return NO;
	return YES;
}

-(void)openItem:(id)item
{
	if (nil == item)
		item = self.arrayController.selectedObjects.firstObject;
	if ([item isKindOfClass:[RCWorkspace class]]) {
		id controller = [TheApp valueForKeyPath:@"delegate.mainWindowController"];
		[controller openSession:item file:nil inNewWindow:NO];
		return;
	}
	if (![item isKindOfClass:[RCProject class]] || [[item workspaces] count] < 1)
		return; //nothing to do
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
}

-(void)displayTopLevel
{
	[self.pathCells removeAllObjects];
	[self.pathCells addObject:[self pathCellWithTitle:@"Project"]];
	[self.pathControl setPathComponentCells:self.pathCells];
	self.arrayController.content = [[[Rc2Server sharedInstance] projects] mutableCopy];
	dispatch_async(dispatch_get_main_queue(), ^{
		NSPathComponentCell *cell = self.pathCells.firstObject;
		[cell setState:NSOffState];
		[self.collectionView setNeedsDisplay:YES];
	});
	self.selectedProject=nil;
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
				[[Rc2Server sharedInstance] createProject:pc.stringValue completionBlock:^(BOOL success, id obj) {
					if (success) {
						NSInteger idx = [[Rc2Server sharedInstance].projects indexOfObject:obj];
								[self.arrayController insertObject:obj atArrangedObjectIndex:idx];
					} else {
						//TODO: notify user that failed
						Rc2LogError(@"failed to create project:%@", obj);
					}
				}];
			} else {
				[[Rc2Server sharedInstance] createWorkspace:pc.stringValue inProject:self.selectedProject completionBlock:^(BOOL success, id obj) {
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
	[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *balert, NSInteger rc) {
		if (NSAlertDefaultReturn == rc) {
			//TODO: remove the selected project
			[[Rc2Server sharedInstance] deleteProject:selObj completionBlock:^(BOOL success, id obj) {
				if (success) {
					[self.arrayController removeObject:selObj];
				} else {
					//TODO: notify user that failed
					Rc2LogError(@"failed to create project:%@", obj);
				}
			}];
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
	[self.pathCells addObject:[self pathCellWithTitle:project.name]];
	[self.pathControl setPathComponentCells:self.pathCells];
	[self.arrayController removeObjects:self.arrayController.arrangedObjects];
	if (project.workspaces.count > 0)
		[self.arrayController addObjects:project.workspaces];
}

-(void)collectionView:(MacProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item
{
	[self openItem:item];
}

-(void)collectionView:(MacProjectCollectionView*)cview deleteBackwards:(id)sender
{
	[self removeSelectedProjects:cview];
}

-(void)collectionView:(MacProjectCollectionView *)cview swipeBackwards:(NSEvent*)event
{
	if (self.selectedProject)
		[self displayTopLevel];
}

-(void)collectionView:(MacProjectCollectionView *)cview renameItem:(id)item name:(NSString*)newName
{
	NSLog(@"should change %@ to %@", [item name], newName);
}

@end
