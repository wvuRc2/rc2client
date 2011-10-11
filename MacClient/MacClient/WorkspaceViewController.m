//
//  WorkspaceViewController.m
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "WorkspaceViewController.h"
#import "RCWorkspace.h"

@interface WorkspaceViewController()
@property (nonatomic, strong) NSMutableSet *kvoTokens;
@end

@implementation WorkspaceViewController

-(id)initWithWorkspace:(RCWorkspace*)aWorkspace
{
	self = [super initWithNibName:@"WorkspaceViewController" bundle:nil];
	if (self) {
		self.workspace = aWorkspace;
		self.kvoTokens = [NSMutableSet set];
		__unsafe_unretained WorkspaceViewController *blockSelf = self;
		[self.kvoTokens addObject:[self.workspace addObserverForKeyPath:@"files" task:^(id obj, NSDictionary *change)
	   {
			[blockSelf.filesTableView reloadData];
	   }]];
	}
	return self;
}

#pragma mark - standard shit

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(doRefreshFileList:)) {
		return YES;
	}
	return NO;
}

#pragma mark - actions

-(IBAction)doRefreshFileList:(id)sender
{

}

#pragma mark - table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.workspace.files count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [self.workspace.files objectAtIndex:row];
}


@synthesize workspace;
@synthesize filesTableView;
@synthesize kvoTokens;
@end
