//
//  iSettingsController.m
//  Rc2
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "iSettingsController.h"
#import "Rc2AppConstants.h"
#import "ThemeEngine.h"
#import "Rc2AppDelegate.h"
#import "Vyana-ios/AMNavigationTreeController.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "DropboxFolderSelectController.h"

enum { eTree_Theme, eTree_Keyboard };

@interface iSettingsController() {
	int _treeType;
}
@property (nonatomic, weak) IBOutlet UITableView *settingsTable;
@property (nonatomic, weak) IBOutlet UITableViewCell *themeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *emailCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *twitterCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *smsCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *emailNoteCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *editThemeCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *editorCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *dbpathCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *logoutCell;
@property (nonatomic, weak) IBOutlet UISwitch *editorSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *emailNoteSwitch;
@property (nonatomic, weak) IBOutlet UIButton *editThemeButton;
@property (nonatomic, weak) IBOutlet UILabel *themeLabel;
@property (nonatomic, weak) IBOutlet UILabel *dbpathLabel;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *twitterField;
@property (nonatomic, weak) IBOutlet UITextField *smsField;
@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) AMNavigationTreeController *treeController;
@property (nonatomic, copy) NSArray *themes;
@property (nonatomic, copy) NSArray *sectionData;
-(IBAction)dismiss:(id)sender;
@end

@implementation iSettingsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		self.navigationItem.title = @"Settings";
		id myThemes= [[[[ThemeEngine sharedInstance] allThemes] valueForKey:@"name"] mutableCopy];
		self.themes = myThemes;
	}
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	NSDictionary *settings = [[Rc2Server sharedInstance] userSettings];
	self.emailField.text = [settings objectForKey:@"email"];
	self.smsField.text = [settings objectForKey:@"smsphone"];
	self.twitterField.text = [settings objectForKey:@"twitter"];
	self.emailNoteSwitch.on = [[settings objectForKey:@"noteByEmail"] boolValue];
	ThemeEngine *te = [ThemeEngine sharedInstance];
	Theme *curTheme = te.currentTheme;
	self.themeLabel.text = curTheme.name;

	NSArray *settingsCells = @[self.themeCell];
	if ([[Rc2Server  sharedInstance] isAdmin])
		settingsCells = [settingsCells arrayByAddingObject:self.editThemeCell];
	self.sectionData = @[
		@{@"name":@"Account", @"isSettings": @NO, @"cells": @[self.emailCell,self.emailNoteCell,self.twitterCell,self.smsCell,self.logoutCell]},
		@{@"name":@"Settings", @"isSettings": @YES,  @"cells": settingsCells}
	];
	if (self.currentWorkspace) {
		NSString *sectitle = [NSString stringWithFormat:@"Workspace %@ Settings", self.currentWorkspace.name];
		self.sectionData = @[@{@"name":sectitle, @"isSettings":@NO, @"cells":@[self.dbpathCell]}, self.sectionData[0], self.sectionData[1]];
		self.dbpathLabel.text = self.currentWorkspace.dropboxPath;
	}
	CGRect newFrame = CGRectMake(0, 0, self.settingsTable.bounds.size.width, self.headerView.frame.size.height);
	self.headerView.backgroundColor = [UIColor clearColor];
	self.headerView.frame = newFrame;
	self.settingsTable.tableFooterView = self.headerView;
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	self.versionLabel.text = [NSString stringWithFormat:@"%@ %@ (Build %@)", info[@"CFBundleDisplayName"], info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.currentWorkspace)
		self.dbpathLabel.text = self.currentWorkspace.dropboxPath;
	[self.settingsTable reloadData];
	[self.view setNeedsLayout];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	CGSize sz = self.settingsTable.contentSize;
	sz.height += self.settingsTable.tableFooterView.bounds.size.height;
	[self.containingPopover setPopoverContentSize:sz animated:NO];
	[self.view setNeedsLayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

-(IBAction)logout:(id)sender
{
	[self.containingPopover dismissPopoverAnimated:YES];
	[(Rc2AppDelegate*)TheApp.delegate logout:sender];
}

-(IBAction)dismiss:(id)sender
{
	[self.containingPopover dismissPopoverAnimated:YES];
}

-(IBAction)emailNoteChanged:(id)sender
{
	[self updateUserSetting:@"noteByEmail" withValue:[NSNumber numberWithBool:self.emailNoteSwitch.on] success:^(NSInteger status)
	{
		if (status != 0)
			self.emailNoteSwitch.on = !self.emailNoteSwitch.on;
	}];
}

-(IBAction)editTheme:(id)sender
{
	[self.containingPopover dismissPopoverAnimated:YES];
	[(Rc2AppDelegate*)TheApp.delegate editTheme:self];
}

-(void)updateUserSetting:(NSString*)name withValue:(id)val success:(BasicBlock1IntArg)sblock
{
	[[Rc2Server sharedInstance] updateUserSettings:@{name:val} completionHandler:^(BOOL success, id results)
	{
		if (success) {
			int status = [[results objectForKey:@"status"] integerValue];
			sblock(status);
		}
	}];
/*	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"user"];
	[req setRequestMethod:@"PUT"];
	[req appendPostData:[[[NSDictionary dictionaryWithObject:val forKey:name] JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
	[req startSynchronous];
	if (req.responseStatusCode == 200) {
		NSDictionary *d = [req.responseString JSONValue];
		int status = [[d objectForKey:@"status"] integerValue];
		if (0 == status)
			return YES;
		if (2 == status)
			[UIAlertView showAlertWithTitle:@"Warning" message:[d objectForKey:@"message"]];
		else
			[UIAlertView showAlertWithTitle:@"Error" message:[d objectForKey:@"message"]];
	} else {
		[UIAlertView showAlertWithTitle:@"Error" message:@"unknown error contacting server"];
	}
	return NO;*/
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	if (textField == self.twitterField) {
		[self updateUserSetting:@"twitter" withValue:textField.text success:^(NSInteger status) {
			if (status != 0)
				textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"twitter"];
		}];
	} else if (textField == self.smsField) {
		[self updateUserSetting:@"smsphone" withValue:textField.text success:^(NSInteger status) {
			if (status != 0)
				textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"smsphone"];
		}];
	} else if (textField == self.emailField) {
		[self updateUserSetting:@"email" withValue:textField.text success:^(NSInteger status) {
			if (status != 0)
				textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"email"];
		}];
	}
	return NO;
}

#pragma mark - table view

-(UITableViewCell*)cellAtIndexPath:(NSIndexPath*)ipath
{
	return [[[self.sectionData objectAtIndex:ipath.section] objectForKey:@"cells"] objectAtIndex:ipath.row];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.sectionData.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[self.sectionData objectAtIndex:section] objectForKey:@"cells"] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [[[self.sectionData objectAtIndex:indexPath.section] objectForKey:@"cells"] objectAtIndex:indexPath.row];
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self.sectionData objectAtIndex:section] objectForKey:@"name"];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id cell = [self cellAtIndexPath:indexPath];
	if ([[[self.sectionData objectAtIndex:indexPath.section] objectForKey:@"isSettings"] boolValue])
		return indexPath; //all settings rows are selectable
	if (cell == self.emailCell || cell == self.dbpathCell)
		return indexPath;
	return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	id cell = [self cellAtIndexPath:indexPath];
	if ([[[self.sectionData objectAtIndex:indexPath.section] objectForKey:@"isSettings"] boolValue]) {
			self.treeController = [[AMNavigationTreeController alloc] init];
			self.treeController.tracksSelectedItem=YES;
			self.treeController.delegate = (id)self;
			self.treeController.preferredContentSize = self.preferredContentSize;
			self.treeController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		if (cell == self.themeCell) {
			_treeType = eTree_Theme;
			self.treeController.title = @"Select Theme";
			self.treeController.contentItems = self.themes;
			self.treeController.selectedItem = [[[ThemeEngine sharedInstance] currentTheme] name];
		}
		[self.navigationController pushViewController:self.treeController animated:YES];
	} else if (cell == self.dbpathCell) {
		[self presentDropboxImport:indexPath];
	}
}

-(void)presentDropboxImport:(NSIndexPath*)ipath
{
	Rc2AppDelegate *del = (Rc2AppDelegate*)[TheApp delegate];
	if ([[DBSession sharedSession] isLinked]) {
		del.dropboxCompletionBlock = nil;
		//push a dropbox browser on navigation stack
		DropboxFolderSelectController *dbc = [[DropboxFolderSelectController alloc] init];
		dbc.workspace = self.currentWorkspace;
		dbc.doneButtonTitle = @"Select";
		dbc.dropboxCache = [[NSMutableDictionary alloc] init];
		dbc.preferredContentSize = self.containingPopover.popoverContentSize;
		dbc.doneHandler = ^(DropboxFolderSelectController *controller, NSString *thePath) {
			self.currentWorkspace.dropboxPath = thePath;
			self.currentWorkspace.dropboxUser = [[[DBSession sharedSession] userIds] firstObject];
			[[Rc2Server sharedInstance] updateWorkspace:self.currentWorkspace completionBlock:^(BOOL success, id results) {
				if (!success)
					Rc2LogError(@"Failed to save db sync info:%@", results);
			}];
			[self.navigationController popToRootViewControllerAnimated:YES];
		};
		//if there is a pre-existing path. we need to build up the nav controller's stack history
		NSMutableArray *controllers = [NSMutableArray array];
		[controllers addObject:dbc];
		DropboxFolderSelectController *top = dbc;
		NSString *curPath = @"/";
		NSArray *pathParts = [dbc.workspace.dropboxPath componentsSeparatedByString:@"/"];
		for (NSString *aPathPart in pathParts) {
			if (aPathPart.length < 1)
				continue;
			//push each path part on
			curPath = [curPath stringByAppendingPathComponent:aPathPart];
			top = [top prepareChildControllerForPath:curPath];
			[top view]; //force loading
			[controllers addObject:top];
		}
		top = controllers.lastObject;
		[controllers removeLastObject];
		//now show all except last one w/o animation
		for (DropboxFolderSelectController *aController in controllers) {
			[self.navigationController pushViewController:aController animated:NO];
		}
		//animate the top one
		[self.navigationController pushViewController:top animated:YES];
	} else {
		//we need to prompt the user to link to us. we need to let the app delegate know
		//to call this object/action on a successful link
		__weak iSettingsController *blockSelf = self;
		del.dropboxCompletionBlock = ^{
			if (blockSelf.view.window)
				[blockSelf tableView:self.settingsTable didSelectRowAtIndexPath:ipath];
		};
		[[DBSession sharedSession] linkFromController:self.view.window.rootViewController];
	}
	
}

-(void)navTree:(AMNavigationTreeController*)navTree leafItemTouched:(id)item
{
	if (_treeType == eTree_Theme) {
		Theme *theme = [[[ThemeEngine sharedInstance] allThemes] firstObjectWithValue:item forKey:@"name"];
		if (theme)
			[[ThemeEngine sharedInstance] setCurrentTheme:theme];
		self.themeLabel.text = item;
	}
	[self.navigationController popToRootViewControllerAnimated:YES];
}

@end
