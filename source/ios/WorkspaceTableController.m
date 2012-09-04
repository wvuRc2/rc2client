//
//  WorkspaceTableController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "WorkspaceTableController.h"
#import "RCWorkspace.h"
#import "RCWorkspaceFolder.h"
#import "Rc2Server.h"
#import "WorkspaceTableCell.h"
#import "ThemeEngine.h"

@interface WorkspaceTableController() {
	BOOL _didInitialLoad;
}
@property (nonatomic, strong) id loggedInToken;
@property (nonatomic, strong) UIActionSheet *addSheet;
@property (nonatomic, strong) WorkspaceTableCell *currentSelection;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) id themeChangeNotice;
@property (nonatomic, strong) UIAlertView *currentAlert;
-(void)handleAddWorkspaceResponse:(BOOL)success results:(NSDictionary*)results;
@end

@implementation WorkspaceTableController

- (id)initWithStyle:(UITableViewStyle)style
{
	return [super initWithStyle:style];
}

-(void)dealloc
{
	if (self.loggedInToken)
		[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.loggedInToken];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationsReceivedNotification object:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	if (!_didInitialLoad) {
		_didInitialLoad=YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged:) name:NotificationsReceivedNotification object:nil];
		__block __weak WorkspaceTableController *blockSelf = self;
		Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
		[[ThemeEngine sharedInstance] addBackgroundLayer:self.view.layer 
												 withKey:@"MasterBackground"
												   frame:self.view.bounds];
		self.view.backgroundColor = [theme colorForKey:@"MasterBackground"];
		id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *aTheme) {
			blockSelf.view.backgroundColor = [aTheme colorForKey:@"MasterBackground"];
			[[ThemeEngine sharedInstance] addBackgroundLayer:blockSelf.view.layer 
													 withKey:@"MasterBackground"
													   frame:blockSelf.view.bounds];
		}];
		self.themeChangeNotice = tn;
		((AMTableView*)self.tableView).deselectOnTouchesOutsideCells=YES;
		self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																		target:self
																		action:@selector(doAdd:)];
		self.toolbarItems = ARRAY(self.addButton);
		self.navigationController.toolbarHidden=NO;
		[[Rc2Server sharedInstance] addObserverForKeyPath:@"loggedIn" task:^(id obj, NSDictionary *change) {
			blockSelf.addButton.enabled = [Rc2Server sharedInstance].loggedIn;
		}];
		UILongPressGestureRecognizer *lpr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnFile:)];
		lpr.minimumPressDuration = 0.5;
		[self.tableView addGestureRecognizer:lpr];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

- (IBAction)doAdd:(id)sender
{
	if (nil == self.addSheet) {
		self.addSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:nil
									   destructiveButtonTitle:nil 
											otherButtonTitles:@"Add Workspace", @"Add Folder",nil];
	}
	[self.addSheet showFromBarButtonItem:self.addButton animated:YES];
}

-(void)handleAddWorkspaceResponse:(BOOL)success results:(id)results
{
	if (!success) {
		NSString *err=nil;
		if ([results isKindOfClass:[NSString class]])
			err = [results description];
		else
			err = [results objectForKey:@"error"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:err
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
	self.workspaceItems = [self.workspaceItems arrayByAddingObject:results];
	[self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0)
		return;
	NSString *title=@"Workspace Name:";
	if (buttonIndex == 1)
		title = @"Folder Name:";
	self.currentAlert = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	__unsafe_unretained WorkspaceTableController *blockSelf=self;
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (1==btnIdx) {
			RCWorkspaceFolder *parent = (RCWorkspaceFolder*)self.parentItem;
			[[Rc2Server sharedInstance] addWorkspace:[alert textFieldAtIndex:0].text parent:parent folder:buttonIndex==1
								   completionHandler:^(BOOL success, id results) {
									   [self handleAddWorkspaceResponse:success results:results];
								   }];
		}
		blockSelf.currentAlert=nil;
	}];
}

#pragma mark - meat & potatos

-(void)loginChanged:(NSNotification*)note
{
	self.workspaceItems = [[Rc2Server sharedInstance] workspaceItems];
}

-(void)clearSelection
{
	self.currentSelection.drawSelected = NO;
	self.currentSelection = nil;
	[self.tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
}

-(void)deleteWorkspace:(id)wsitem
{
	if ([wsitem isKindOfClass:[AMActionItem class]])
		wsitem = [wsitem userInfo];
	__unsafe_unretained WorkspaceTableController *blockSelf = self;
	NSString *msg = [NSString stringWithFormat:@"Delete Workspace '%@'? This action can not be undone.", 
					 [wsitem name]];
	if ([wsitem isFolder])
		msg = [NSString stringWithFormat:@"Delete Folder '%@' and all contents? This action can not be undone.", 
					 [wsitem name]];
	self.currentAlert = [[UIAlertView alloc] initWithTitle:@"Delete Workspace?" message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (btnIdx == 1) {
			[[Rc2Server sharedInstance] deleteWorkspce:wsitem completionHandler:^(BOOL success, id msg) {
				NSInteger idx = [self.workspaceItems indexOfObject:wsitem];
				blockSelf.workspaceItems = [blockSelf.workspaceItems arrayByRemovingObjectAtIndex:idx];
				[blockSelf.tableView reloadData];
				if (!success) {
					dispatch_async(dispatch_get_main_queue(), ^{
						UIAlertView *msgview = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
						[msgview show];
					});
				}
			}];
		}
		self.currentAlert=nil;
	}];
}

-(void)renameWorkspace:(id)wsitem
{
	if ([wsitem isKindOfClass:[AMActionItem class]])
		wsitem = [wsitem userInfo];
	__unsafe_unretained WorkspaceTableController *blockSelf = self;
	NSString *msg = [NSString stringWithFormat:@"Rename '%@':", [wsitem name]];
	self.currentAlert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[self.currentAlert textFieldAtIndex:0].text = [wsitem name];
	[self.currentAlert textFieldAtIndex:0].clearButtonMode = UITextFieldViewModeAlways;
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (btnIdx == 1) {
			NSString *newName = [alert textFieldAtIndex:0].text;
			[[Rc2Server sharedInstance] renameWorkspce:wsitem name:newName completionHandler:^(BOOL success, id msg) {
				if (success) {
					[blockSelf.tableView reloadData];
				} else {
					dispatch_async(dispatch_get_main_queue(), ^{
						UIAlertView *msgview = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
						[msgview show];
					});
				}
			}]; 
		}
		self.currentAlert=nil;
	}];
}

-(void)longPressOnFile:(UILongPressGestureRecognizer*)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan) {
		if (self.actionSheet) {
			[self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
			self.actionSheet = nil;
		}
		CGPoint pt = [gesture locationInView:self.tableView];
		NSIndexPath *ipath = [self.tableView indexPathForRowAtPoint:pt];
		NSMutableArray *items = [NSMutableArray array];
		RCWorkspaceItem *selItem = [self.workspaceItems objectAtIndex:ipath.row];
		if (selItem.canRename)
			[items addObject:[AMActionItem actionItemWithName:@"Rename" target:self action:@selector(renameWorkspace:) userInfo:selItem]];
		if (selItem.canDelete)
			[items addObject:[AMActionItem actionItemWithName:@"Delete" target:self action:@selector(deleteWorkspace:) userInfo:selItem]];
		if (items.count > 0) {
			self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Actions" actionItems:items];
			CGRect r = CGRectMake(pt.x, pt.y, 1, 1);
			[self.actionSheet showFromRect:r inView:self.tableView animated:YES];
		}
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.workspaceItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	WorkspaceTableCell *cell = [WorkspaceTableCell cellForTableView:tableView];
	RCWorkspaceItem *item = [self.workspaceItems objectAtIndex:indexPath.row];
	cell.item = item;
	return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSIndexPath *oldPath = [tableView indexPathForSelectedRow];
	if (oldPath == indexPath) {
		RunAfterDelay(0, ^{
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			[Rc2Server sharedInstance].selectedWorkspace=nil;
			self.currentSelection.drawSelected=NO;
			self.currentSelection=nil;
		});
		return nil;
	}
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	WorkspaceTableCell *newCell = (WorkspaceTableCell*)[tableView cellForRowAtIndexPath:indexPath];

	newCell.drawSelected = YES;
	self.currentSelection.drawSelected = NO;
	self.currentSelection = newCell;

	RCWorkspaceItem *wsitem = [_workspaceItems objectAtIndex:indexPath.row];
	if (wsitem.isFolder) {
		WorkspaceTableController *tc = [[WorkspaceTableController alloc] initWithNibName:@"WorkspaceTableController" bundle:nil];
		tc.workspaceItems = ((RCWorkspaceFolder*)wsitem).children;
		tc.parentItem = wsitem;
		tc.navigationItem.title = wsitem.name;
		[self.navigationController pushViewController:tc animated:YES];
	} else {
		RCWorkspace *wspace = (RCWorkspace*)wsitem;
		[Rc2Server sharedInstance].selectedWorkspace = wspace;
	}
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.currentSelection.drawSelected=NO;
	self.currentSelection=nil;
	[Rc2Server sharedInstance].selectedWorkspace = nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCWorkspaceItem *wsitem = [_workspaceItems objectAtIndex:indexPath.row];
	[self deleteWorkspace:wsitem];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCWorkspaceItem *wsitem = [_workspaceItems objectAtIndex:indexPath.row];
	if (wsitem.canDelete)
		return UITableViewCellEditingStyleDelete;
	return UITableViewCellEditingStyleNone;
}

#pragma mark - accessors

-(void)setWorkspaceItems:(NSArray *)items
{
	if (_workspaceItems == items)
		return;
	_workspaceItems = [items copy];
	[self.tableView reloadData];
}
@end
