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
#import "Rc2AppDelegate.h"
#import "MAKVONotificationCenter.h"
#import "MBProgressHUD.h"

@interface ProjectViewController () <UICollectionViewDataSource,UICollectionViewDelegate>
@property (weak) IBOutlet UIBarButtonItem *addButton;
@property (weak) IBOutlet UIBarButtonItem *projectButton;
@property (weak) IBOutlet UIBarButtonItem *titleItem;
@property (weak) IBOutlet UICollectionView *collectionView;
@property (strong) UIActionSheet *contextMenuSheet;
@property (strong) NSMutableArray *projects;
@property (strong) RCProject *selectedProject;
@end

#define CV_ANIM_DELAY 0.2

@implementation ProjectViewController {
	BOOL _transitioning;
	BOOL _doingInitialLoad;
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
	__weak ProjectViewController *bself = self;
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"loggedIn" selector:@selector(loginStatusChanged) userInfo:nil options:0];
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"projects" options:0 block:^(MAKVONotification *notification) {
		bself.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
		[bself.collectionView reloadData];
	}];
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	ProjectViewLayout *flow = [[ProjectViewLayout alloc] init];
	[flow setItemSize:CGSizeMake(200, 150)];
	self.collectionView.collectionViewLayout = flow;
	self.collectionView.allowsSelection = YES;
	[self.collectionView registerClass:[ProjectCell class] forCellWithReuseIdentifier:@"project"];
	[self.collectionView reloadData];
	UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGesture:)];
	[self.collectionView addGestureRecognizer:g];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (![Rc2Server sharedInstance].loggedIn) {
		_doingInitialLoad = YES;
		[[MBProgressHUD showHUDAddedTo:self.view.window animated:YES] setLabelText:@"Loading Projects"];
	}
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
	if (_doingInitialLoad) {
		[MBProgressHUD hideAllHUDsForView:self.view.window animated:YES];
		_doingInitialLoad = NO;
	}
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	[self.collectionView reloadData];
	self.projectButton.title = @"Logout";
	self.selectedProject = nil;
	self.titleItem.title = NSLocalizedString(@"Rc2 Projects", @"");
}

-(void)longGesture:(UILongPressGestureRecognizer*)gesture
{
	NSIndexPath *ipath = [_collectionView indexPathForItemAtPoint:[gesture locationInView:_collectionView]];
	id item=nil;
	if (nil == _selectedProject)
		item = [self.projects objectAtIndex:ipath.row];
	else
		item = [_selectedProject.workspaces objectAtIndex:ipath.row];
	if ([item isKindOfClass:[RCProject class]] && ![item userEditable])
		return;
	
	NSArray *items = @[ [AMActionItem actionItemWithName:@"Rename" target:self action:@selector(renameObject:) userInfo:@{@"item":item}],
		[AMActionItem actionItemWithName:@"Delete" target:self action:@selector(deleteObject:) userInfo:@{@"item":item}]];
	self.contextMenuSheet = [[UIActionSheet alloc] initWithTitle:@"Actions" actionItems:items];

	CGRect rect = CGRectZero;
	rect.origin = [gesture locationInView:self.collectionView];
	rect.size.width = rect.size.height = 2;
	[self.contextMenuSheet showFromRect:rect inView:self.collectionView animated:YES];
}


#pragma mark - actions

-(IBAction)renameObject:(id)sender
{
	[self.contextMenuSheet dismissWithClickedButtonIndex:-1 animated:YES];
	id item = [[sender userInfo] objectForKey:@"item"];
	if (nil == item)
		return;
	BOOL isProj = [item isKindOfClass:[RCProject class]];
	UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Rename %@ to:", isProj?@"project":@"workspace"]
													  message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
	anAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[anAlert textFieldAtIndex:0].text = [item name];
	__unsafe_unretained ProjectViewController *blockSelf=self;
	[anAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		NSString *str = [alert textFieldAtIndex:0].text;
		if (1!=btnIdx || str.length < 1)
			return;
		if (isProj) {
			[[Rc2Server sharedInstance] editProject:item newName:str completionBlock:^(BOOL success, id rsp) {
				if (success) {
					NSInteger idx = [self.projects indexOfObject:item];
					if (idx != NSNotFound)
							[blockSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
					else
						[blockSelf.collectionView reloadData];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error renaming file" message:rsp delegate:nil
														  cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
					[alert show];
				}
			}];
		} else {
			[[Rc2Server sharedInstance] renameWorkspce:item name:str completionHandler:^(BOOL success, id rsp) {
				if (success) {
					NSInteger idx = [self.projects indexOfObject:item];
					if (idx != NSNotFound)
							[blockSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
					else
						[blockSelf.collectionView reloadData];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error renaming file" message:rsp delegate:nil
														  cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
					[alert show];
				}
			}];
		}
	}];
}

-(IBAction)deleteObject:(id)sender
{
	[self.contextMenuSheet dismissWithClickedButtonIndex:-1 animated:YES];
	id item = [[sender userInfo] objectForKey:@"item"];
	if (nil == item)
		return;
	BOOL isProj = [item isKindOfClass:[RCProject class]];
	NSString *confStr = [NSString stringWithFormat:@"Are you sure you want to delete %@ %@?", isProj?@"project":@"workspace", [item name]];
	UIAlertView *confAlert = [[UIAlertView alloc] initWithTitle:@"Confirm Delete" message:confStr delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
	[confAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger rc) {
		if (1 == rc) {
			if ([item isKindOfClass:[RCProject class]]) {
				[[Rc2Server sharedInstance] deleteProject:item completionBlock:^(BOOL success, id rsp) {
					if (success) {
						NSInteger idx = [self.projects indexOfObject:item];
						self.projects = [[Rc2Server sharedInstance].projects mutableCopy];
						if (idx != NSNotFound)
								[self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
					}
				}];
			} else {
				NSInteger idx = [self.selectedProject.workspaces indexOfObject:item];
				[[Rc2Server sharedInstance] deleteWorkspce:item completionHandler:^(BOOL success, id rsp) {
					if (success) {
						if (idx != NSNotFound)
							[self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
						else
							[self.collectionView reloadData];
					}
				}];
			}
		}
	}];
}

-(IBAction)addNewObject:(id)sender
{
	BOOL isProj = nil == _selectedProject;
	UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:(isProj?@"New project name:":@"New workspace name:") message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	theAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	__unsafe_unretained ProjectViewController *blockSelf=self;
	[theAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (1!=btnIdx)
			return;
		[blockSelf doAddObject:[alert textFieldAtIndex:0].text];
	}];
}

-(IBAction)backToProjects:(id)sender
{
	if (nil == self.selectedProject) {
		//a logout request
		[(Rc2AppDelegate*)TheApp.delegate logout:sender];
		[self.projects removeAllObjects];
		[self.collectionView reloadData];
		return;
	}
	self.projectButton.title = @"Logout";
	[(ProjectViewLayout*)self.collectionView.collectionViewLayout setRemoveAll:YES];
	NSInteger cnt = _selectedProject.workspaces.count;
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:cnt];
	for (NSInteger row=cnt-1; row >= 0; row--)
		[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
	_transitioning = YES;
	if (paths.count > 0)
		[_collectionView deleteItemsAtIndexPaths:paths];
	[(ProjectViewLayout*)_collectionView.collectionViewLayout setRemoveAll:NO];
	[paths removeAllObjects];
	for (NSInteger row=0; row < _projects.count; row++)
		[paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
	RunAfterDelay(CV_ANIM_DELAY, ^{
		_transitioning = NO;
		self.selectedProject = nil;
		[_collectionView insertItemsAtIndexPaths:paths];
		self.titleItem.title = NSLocalizedString(@"Rc2 Projects", @"");
		[[Rc2Server sharedInstance] updateProjects];
	});
}

#pragma mark - meat & potatos

-(void)doAddObject:(NSString*)newNamee
{
	NSString *errMsg=nil;
	if (nil == _selectedProject) {
		if (nil != [self.projects firstObjectWithValue:newNamee forKey:@"name"])
			errMsg = @"A project already exists with that name.";
	} else {
		if (nil != [self.selectedProject.workspaces firstObjectWithValue:newNamee forKey:@"name"])
			errMsg = @"A workspace already exists with that name.";
	}
	if (errMsg) {
		[UIAlertView showAlertWithTitle:@"Unable to create project" message:errMsg];
		return;
	}
	if (nil == _selectedProject) {
		[[Rc2Server sharedInstance] createProject:newNamee completionBlock:^(BOOL success, id rsp) {
			if (success) {
				self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
				NSInteger idx = [self.projects indexOfObject:rsp];
				if (idx != NSNotFound)
					[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
			} else {
				[UIAlertView showAlertWithTitle:@"Failed to create project" message:rsp];
			}
		}];
	} else {
		[[Rc2Server sharedInstance] createWorkspace:newNamee inProject:self.selectedProject completionBlock:^(BOOL sucess, id rsp) {
			if (sucess) {
				NSInteger idx = [self.selectedProject.workspaces indexOfObject:rsp];
				[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
			} else {
				[UIAlertView showAlertWithTitle:@"Failed to create workspace" message:rsp];
			}
		}];
	}
}

#pragma mark - collection view

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
		RunAfterDelay(CV_ANIM_DELAY, ^{
			_transitioning = NO;
			self.selectedProject = selProject;
			if (paths.count > 0)
				[collectionView insertItemsAtIndexPaths:paths];
			self.projectButton.title = @"Projects";
			self.titleItem.title = [NSLocalizedString(@"Project Title Prefix", @"") stringByAppendingString:[selProject name]];
		});
	} else {
		//selected a workspace
		Rc2AppDelegate *del = (Rc2AppDelegate*)[[UIApplication sharedApplication] delegate];
		id wspace = [[_selectedProject workspaces] objectAtIndex:indexPath.row];
		[del openSession:wspace];
	}
}

@end
