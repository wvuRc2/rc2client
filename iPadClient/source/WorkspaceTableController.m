//
//  WorkspaceTableController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
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
@property (nonatomic, retain) id loggedInToken;
@property (nonatomic, retain) UIActionSheet *addSheet;
@property (nonatomic, retain) WorkspaceTableCell *currentSelection;
@property (nonatomic, retain) id themeChangeNotice;
-(void)handleAddWorkspaceResponse:(BOOL)success results:(NSDictionary*)results;
@end

@implementation WorkspaceTableController
@synthesize workspaceItems=_workspaceItems;
@synthesize currentSelection;

- (id)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	if (self) {
		// Custom initialization
	}
	return self;
}

-(void)freeMemory
{
	if (self.loggedInToken)
		[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.loggedInToken];
	self.loggedInToken=nil;
	self.workspaceItems=nil;
    self.addButton=nil;
	self.parentItem=nil;
	self.themeChangeNotice=nil;
}

-(void)dealloc
{
	[self freeMemory];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	if (!_didInitialLoad) {
		_didInitialLoad=YES;
		__block WorkspaceTableController *blockSelf = self;
		Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
		[[ThemeEngine sharedInstance] addBackgroundLayer:self.view.layer 
												 withKey:@"MasterBackground"
												   frame:self.view.bounds];
		self.view.backgroundColor = [theme colorForKey:@"MasterBackground"];
		id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *aTheme) {
			[[ThemeEngine sharedInstance] addBackgroundLayer:blockSelf.view.layer 
													 withKey:@"MasterBackground"
													   frame:blockSelf.view.bounds];
		}];
		self.themeChangeNotice = tn;
		((AMTableView*)self.tableView).deselectOnTouchesOutsideCells=YES;
		self.addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																		target:self
																		action:@selector(doAdd:)] autorelease];
		self.toolbarItems = ARRAY(self.addButton);
		self.navigationController.toolbarHidden=NO;
		[[Rc2Server sharedInstance] addObserverForKeyPath:@"loggedIn" task:^(id obj, NSDictionary *change) {
			blockSelf.addButton.enabled = [Rc2Server sharedInstance].loggedIn;
		}];
	}
}

- (void)viewDidUnload
{
	[self freeMemory];
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

- (IBAction)doAdd:(id)sender
{
	if (nil == self.addSheet) {
		self.addSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:nil
									   destructiveButtonTitle:nil 
											otherButtonTitles:@"Add Workspace", @"Add Folder",nil] autorelease];
	}
	[self.addSheet showFromBarButtonItem:self.addButton animated:YES];
}

-(void)handleAddWorkspaceResponse:(BOOL)success results:(NSDictionary*)results
{
	if (!success) {
		NSString *err=nil;
		if ([results isKindOfClass:[NSString class]])
			err = results.description;
		else
			err = [results objectForKey:@"error"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
														message:err
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	RCWorkspaceItem *wspace = [RCWorkspaceItem workspaceItemWithDictionary:[results objectForKey:@"wspace"]];
	[(RCWorkspaceFolder*)self.parentItem addChild:wspace];
	self.workspaceItems = [self.workspaceItems arrayByAddingObject:wspace];
	[self.tableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0)
		return;
	NSString *title=@"Workspace Name:";
	if (buttonIndex == 1)
		title = @"Folder Name:";
	AMPromptView *pv = [[AMPromptView alloc] initWithPrompt:title 
												acceptTitle:@"Create" cancelTitle:@"Cancel" delegate:nil];
	pv.completionHandler = ^(AMPromptView *prompt, NSString *string) {
		if (string) {
			RCWorkspaceFolder *parent = (RCWorkspaceFolder*)self.parentItem;
			[[Rc2Server sharedInstance] addWorkspace:string parent:parent folder:buttonIndex==1
								   completionHandler:^(BOOL success, id results) {
									   [self handleAddWorkspaceResponse:success results:results];
								   }];
		}
		[prompt autorelease];		
	};
	[pv show];
	[pv autorelease];
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
		[tc release];
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

#pragma mark - accessors

-(void)setWorkspaceItems:(NSArray *)items
{
	if (_workspaceItems == items)
		return;
	[_workspaceItems release];
	_workspaceItems = [items copy];
	[self.tableView reloadData];
}

@synthesize loggedInToken;
@synthesize addSheet;
@synthesize addButton;
@synthesize parentItem;
@synthesize themeChangeNotice;
@end
