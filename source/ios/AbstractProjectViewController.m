//
//  AbstractProjectViewController.m
//  
//
//  Created by Mark Lilback on 8/15/13.
//
//

#import "AbstractProjectViewController.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"
#import "ProjectViewLayout.h"
#import "ProjectCell.h"
#import "ThemeEngine.h"
#import "Rc2AppDelegate.h"
#import "WorkspaceViewController.h"

@interface AbstractProjectViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UIBarPositioningDelegate>
@property (weak) IBOutlet UIBarButtonItem *addButton;
@property (weak) IBOutlet UIBarButtonItem *projectButton;
@property (strong) UIActionSheet *contextMenuSheet;
@property (strong) NSMutableArray *projects;
@property (nonatomic, copy, readwrite) NSArray *standardLeftNavBarItems;
@property (nonatomic, copy, readwrite) NSArray *standardRightNavBarItems;
@property (strong) id myChild; //setting cv delegate in dealloc reloads ourself which is a big crash. this ref saves us from that.
@end

#define CV_ANIM_DELAY 0.2

@implementation AbstractProjectViewController
-(id)init
{
	if ((self = [super initWithCollectionViewLayout:[[ProjectViewLayout alloc] init]])) {
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.myChild = nil;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	self.standardLeftNavBarItems = [(id)[TheApp delegate] standardLeftNavBarItems];
	self.standardRightNavBarItems = [(id)[TheApp delegate] standardRightNavBarItems];
	__weak AbstractProjectViewController *bself = self;
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
		[bself updateForNewTheme:theme];
	}];
	[self updateForNewTheme:[[ThemeEngine sharedInstance] currentTheme]];
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"loggedIn" selector:@selector(loginStatusChanged) userInfo:nil options:0];
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"projects" options:0 block:^(MAKVONotification *notification) {
		bself.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
		[bself.collectionView reloadData];
	}];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note)
	{
		[bself.collectionView reloadData];
	}];
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	ProjectViewLayout *flow = (ProjectViewLayout*)self.collectionViewLayout;
	[flow setItemSize:CGSizeMake(200, 150)];
	self.collectionView.allowsSelection = YES;
	self.collectionView.opaque = YES;
	[self.collectionView registerClass:[ProjectCell class] forCellWithReuseIdentifier:@"project"];
	[self.collectionView reloadData];
	UILongPressGestureRecognizer *g = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGesture:)];
	[self.collectionView addGestureRecognizer:g];
	
	self.navigationItem.leftItemsSupplementBackButton = YES;
	NSMutableArray *leftItems = [self.standardLeftNavBarItems mutableCopy];
	UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStyleBordered target:self action:@selector(addNewObject:)];
	[leftItems insertObject:addItem atIndex:0];
	self.navigationItem.leftBarButtonItems = leftItems;
	self.navigationItem.rightBarButtonItems = self.standardRightNavBarItems;
	self.navigationItem.title = @"Projects";
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.collectionView reloadData];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self adjustConstraints];
	[self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder { return YES;}

-(void)adjustConstraints
{
	if ([self.view.superview constraints].count == 0) {
		id cview = self.view;
		[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[cview]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(cview)]];
		[self.view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cview]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(cview)]];
	}
}

-(void)updateForNewTheme:(Theme*)theme
{
	self.collectionView.layer.backgroundColor = [theme colorForKey:@"WelcomeBackground"].CGColor;
//	[self.view setNeedsDisplay];
}

-(void)loginStatusChanged
{
	self.projects = [[[Rc2Server sharedInstance] projects] mutableCopy];
	[self.collectionView reloadData];
	self.projectButton.title = @"Logout";
	self.selectedProject = nil;
	self.navigationItem.title = NSLocalizedString(@"Rc2 Projects", @"");
}

-(void)longGesture:(UILongPressGestureRecognizer*)gesture
{
	NSIndexPath *ipath = [self.collectionView indexPathForItemAtPoint:[gesture locationInView:self.collectionView]];
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
	__unsafe_unretained AbstractProjectViewController *blockSelf=self;
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
	__unsafe_unretained AbstractProjectViewController *blockSelf=self;
	[theAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (1!=btnIdx)
			return;
		[blockSelf doAddObject:[alert textFieldAtIndex:0].text];
	}];
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
	self.clickedCellFrame = [[self.collectionView cellForItemAtIndexPath:indexPath] frame];
	if (nil == self.selectedProject) {
		//selecting a project
		WorkspaceViewController *wvc = [[WorkspaceViewController alloc] init];
		wvc.selectedProject = [self.projects objectAtIndex:indexPath.row];
//		wvc.useLayoutToLayoutNavigationTransitions = YES;
		[self.navigationController pushViewController:wvc animated:YES];
		self.myChild = wvc;
	} else {
		//selected a workspace
		Rc2AppDelegate *del = (Rc2AppDelegate*)[[UIApplication sharedApplication] delegate];
		id wspace = [[_selectedProject workspaces] objectAtIndex:indexPath.row];
		[del openSession:wspace];
	}
}

@end
