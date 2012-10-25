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

@interface MacProjectViewController () <NSCollectionViewDelegate>
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (strong) IBOutlet NSArrayController *arrayController;
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
//	self.arrayController.content = @[@{@"name":@"Admin"}, @{@"name":@"Shared"}, @{@"name":@"Stat 211"}, @{@"name":@"Stat 523"}];
	self.arrayController.content = [[Rc2Server sharedInstance] projects];
	NSArray *cells = @[[self pathCellWithTitle:@"Top"], [self pathCellWithTitle:@"Stat 523"], [self pathCellWithTitle:@"Assignment 1"]];
	[self.pathControl setPathComponentCells:cells];
//	[self.pathControl.cell setControlSize:NSRegularControlSize];
//	[self.pathControl.cell setControlSize:NSRegularControlSize];
//	[self.pathControl setFont:[NSFont controlContentFontOfSize:NSRegularControlSize]];
}

-(NSPathComponentCell*)pathCellWithTitle:(NSString*)title
{
	NSPathComponentCell *cell = [[NSPathComponentCell alloc] init];
	cell.title = title;
	return cell;
}

@end
