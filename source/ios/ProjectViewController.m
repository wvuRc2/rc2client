//
//  ProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ProjectViewController.h"
#import "ProjectCell.h"
#import "Rc2Server.h"
#import "ThemeEngine.h"
#import "ProjectViewLayout.h"
#import "RCProject.h"
#import "RCWorkspace.h"

@interface ProjectViewController () <UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak) IBOutlet UIBarButtonItem *projectButton;
@property (weak) IBOutlet UICollectionView *collectionView;
@property (strong) NSMutableArray *projects;
@property (strong) RCProject *selectedProject;
@end

@implementation ProjectViewController {
	BOOL _transitioning;
}

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	if (![Rc2Server sharedInstance].loggedIn) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged) name:NotificationsReceivedNotification object:nil];
	}
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	ProjectViewLayout *flow = [[ProjectViewLayout alloc] init];
	[flow setItemSize:CGSizeMake(200, 150)];
	self.collectionView.collectionViewLayout = flow;
	self.collectionView.allowsSelection = YES;
	[self.collectionView registerClass:[ProjectCell class] forCellWithReuseIdentifier:@"project"];
	[self.collectionView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}

-(void)loginStatusChanged
{
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	[self.collectionView reloadData];
}

-(IBAction)backToProjects:(id)sender
{
	self.projectButton.enabled = NO;
	[(ProjectViewLayout*)self.collectionView.collectionViewLayout setRemoveAll:YES];
	NSInteger cnt = _selectedProject.workspaces.count;
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:cnt];
	for (NSInteger row=cnt-1; row >= 0; row--)
		[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
	_transitioning = YES;
	[_collectionView deleteItemsAtIndexPaths:paths];
	[(ProjectViewLayout*)_collectionView.collectionViewLayout setRemoveAll:NO];
	[paths removeAllObjects];
	for (NSInteger row=0; row < _projects.count; row++)
		[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
	RunAfterDelay(0.2, ^{
		_transitioning = NO;
		self.selectedProject = nil;
		[_collectionView insertItemsAtIndexPaths:paths];
	});
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	if (_transitioning)
		return 0;
	if (self.selectedProject)
		return self.selectedProject.workspaces.count;
	return self.projects.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ProjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"project" forIndexPath:indexPath];
	if (nil == _selectedProject)
		cell.cellItem = [self.projects objectAtIndex:indexPath.row];
	else
		cell.cellItem = [_selectedProject.workspaces objectAtIndex:indexPath.row];
	return cell;
	
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (nil == self.selectedProject) {
		//selecting a project
		[(ProjectViewLayout*)collectionView.collectionViewLayout setRemoveAll:YES];
		NSMutableArray *paths = [NSMutableArray arrayWithCapacity:self.projects.count];
		for (NSInteger row=self.projects.count-1; row >= 0; row--)
			[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
		id selProject = [self.projects objectAtIndex:indexPath.row];
		_transitioning = YES;
		[collectionView deleteItemsAtIndexPaths:paths];
		[(ProjectViewLayout*)collectionView.collectionViewLayout setRemoveAll:NO];
		[paths removeAllObjects];
		for (NSInteger row=0; row < [selProject workspaces].count; row++)
			[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
		RunAfterDelay(0.2, ^{
			_transitioning = NO;
			self.selectedProject = selProject;
			[collectionView insertItemsAtIndexPaths:paths];
			self.projectButton.enabled = YES;
		});
	} else {
		//selected a workspace
	}
}

@end
