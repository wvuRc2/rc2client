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

@interface MacProjectViewController () <ProjectCollectionDelegate>
@property (weak) IBOutlet MacProjectCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) NSMutableArray *pathCells;
@property (weak) IBOutlet NSPathControl *pathControl;
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
}

-(IBAction)pathControlClicked:(id)sender
{
	NSUInteger idx = [self.pathCells indexOfObject:[self.pathControl clickedPathComponentCell]];
	ZAssert(idx != NSNotFound, @"impossible cell clicked");
	[self.pathControl.clickedPathComponentCell setState:NSOffState];
	if (idx+1 == self.pathCells.count)
		return; //clicked the current level
	if (idx == 0) {
		[self.pathCells removeAllObjects];
		[self.pathCells addObject:[self pathCellWithTitle:@"Project"]];
		[self.pathControl setPathComponentCells:self.pathCells];
		self.arrayController.content = [[[Rc2Server sharedInstance] projects] mutableCopy];
		dispatch_async(dispatch_get_main_queue(), ^{
			NSPathComponentCell *cell = self.pathCells.firstObject;
			[cell setState:NSOffState];
			[self.collectionView setNeedsDisplay:YES];
		});
	} else {
		ZAssert(NO, @"not implemented");
	}
}

-(IBAction)addSomeProjects:(id)sender
{
	RCProject *p1 = [[RCProject alloc] initWithDictionary:@{@"name":@"foobar"}];
	[self.arrayController addObject:p1];
}

-(NSPathComponentCell*)pathCellWithTitle:(NSString*)title
{
	NSPathComponentCell *cell = [[NSPathComponentCell alloc] init];
	cell.title = title;
	return cell;
}

-(void)replaceItemsWithChildrenOf:(RCProject*)project
{
	[self.pathCells addObject:[self pathCellWithTitle:project.name]];
	[self.pathControl setPathComponentCells:self.pathCells];
	[self.arrayController removeObjects:self.arrayController.arrangedObjects];
	if (project.subprojects.count > 0)
		[self.arrayController addObjects:project.subprojects];
	if (project.workspaces.count > 0)
		[self.arrayController addObjects:project.workspaces];
}

-(void)collectionView:(MacProjectCollectionView *)cview doubleClicked:(NSEvent*)event item:(id)item
{
	if ([item isKindOfClass:[RCWorkspace class]]) {
		id controller = [TheApp valueForKeyPath:@"delegate.mainWindowController"];
		[controller openSession:item file:nil inNewWindow:NO];
		return;
	}
	if (![item isKindOfClass:[RCProject class]] || [item childCount] < 1)
		return; //nothing to do
	NSRect centerRect = [cview frameForItemAtIndex:0];
	NSSize viewSize = self.view.frame.size;
	centerRect.origin.x = floorf((viewSize.width - centerRect.size.width) / 2);
	centerRect.origin.y = floorf((viewSize.height - centerRect.size.height) / 2);
	[NSAnimationContext beginGrouping];
	[NSAnimationContext currentContext].duration = 0.4;
	for (NSInteger i=0; i < [self.arrayController.arrangedObjects count]; i++) {
		NSCollectionViewItem *item = [cview itemAtIndex:i];
		[item.view.animator setFrame:centerRect];
	}
	[NSAnimationContext currentContext].completionHandler = ^{
		[self replaceItemsWithChildrenOf:item];
	};
	[NSAnimationContext endGrouping];
}

-(void)collectionView:(MacProjectCollectionView*)cview deleteBackwards:(id)sender
{
	NSIndexSet *selSet = [cview selectionIndexes];
	if (selSet.count < 1) {
		NSBeep();
		return;
	}
	[_arrayController removeObjectsAtArrangedObjectIndexes:selSet];
}

@end
