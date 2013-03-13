//
//  iSettingsController.m
//  Rc2
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "iSettingsController.h"
#import "AppConstants.h"
#import "ThemeEngine.h"
#import "Rc2AppDelegate.h"
#import "Vyana-ios/AMNavigationTreeController.h"
#import "Rc2Server.h"
#import "GradientButton.h"
#import "ASIFormDataRequest.h"

enum { eTree_Theme, eTree_Keyboard };

@interface iSettingsController() {
	int _treeType;
}
@property (nonatomic, strong) AMNavigationTreeController *treeController;
@property (nonatomic, copy) NSArray *keyboards;
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
		self.keyboards = ARRAY(@"Default", @"Custom 1", @"Custom 2");
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	switch ([defaults integerForKey:kPrefKeyboardLayout]) {
		case 0:
		default:
			self.keyboardLabel.text = @"Default";
			break;
		case 1:
			self.keyboardLabel.text = @"Custom 1";
			break;
		case 2:
			self.keyboardLabel.text = @"Custom 2";
			break;
	}
	NSDictionary *settings = [[Rc2Server sharedInstance] userSettings];
	self.emailField.text = [settings objectForKey:@"email"];
	self.smsField.text = [settings objectForKey:@"smsphone"];
	self.twitterField.text = [settings objectForKey:@"twitter"];
	self.emailNoteSwitch.on = [[settings objectForKey:@"noteByEmail"] boolValue];
	ThemeEngine *te = [ThemeEngine sharedInstance];
	Theme *curTheme = te.currentTheme;
	self.themeLabel.text = curTheme.name;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self action:@selector(dismiss:)];
	self.sectionData = @[
		@{@"name":@"Account", @"isSettings": @NO, @"cells": @[self.logoutCell, self.emailCell,self.emailNoteCell,self.twitterCell,self.smsCell]},
		@{@"name":@"Settings", @"isSettings": @YES,  @"cells": @[self.keyboardCell,self.themeCell]}
	];
	[self.logoutButton useWhiteStyle];
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
	if (![self updateUserSetting:@"noteByEmail" withValue:[NSNumber numberWithBool:self.emailNoteSwitch.on]])
	{
		self.emailNoteSwitch.on = !self.emailNoteSwitch.on;
	}
}

-(BOOL)updateUserSetting:(NSString*)name withValue:(id)val
{
	ASIFormDataRequest *req = [[Rc2Server sharedInstance] postRequestWithRelativeURL:@"user"];
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
	return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	if (textField == self.twitterField) {
		if (![self updateUserSetting:@"twitter" withValue:textField.text]) {
			textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"twitter"];
		}
	} else if (textField == self.smsField) {
		if (![self updateUserSetting:@"smsphone" withValue:textField.text]) {
			textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"smsphone"];
		}
	} else if (textField == self.emailField) {
		if (![self updateUserSetting:@"email" withValue:textField.text]) {
			textField.text = [[Rc2Server sharedInstance].userSettings objectForKey:@"email"];
		}
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
	if (cell == self.emailCell)
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
			self.treeController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
			self.treeController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		if (cell == self.keyboardCell) {
			_treeType = eTree_Keyboard;
			self.treeController.title = @"Select Keyboard";
			self.treeController.contentItems = self.keyboards;
			NSInteger k = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefKeyboardLayout];
			self.treeController.selectedItem = [self.keyboards objectAtIndex:k];
		} else if (cell == self.themeCell) {
			_treeType = eTree_Theme;
			self.treeController.title = @"Select Theme";
			self.treeController.contentItems = self.themes;
			self.treeController.selectedItem = [[[ThemeEngine sharedInstance] currentTheme] name];
		}
		[self.navigationController pushViewController:self.treeController animated:YES];
	}
}

-(void)navTree:(AMNavigationTreeController*)navTree leafItemTouched:(id)item
{
	if (_treeType == eTree_Theme) {
		Theme *theme = [[[ThemeEngine sharedInstance] allThemes] firstObjectWithValue:item forKey:@"name"];
		if (theme)
			[[ThemeEngine sharedInstance] setCurrentTheme:theme];
		self.themeLabel.text = item;
	} else if (_treeType == eTree_Keyboard) {
		[[NSUserDefaults standardUserDefaults] setInteger:[self.keyboards indexOfObject:item] forKey:kPrefKeyboardLayout];
		[[NSNotificationCenter defaultCenter] postNotificationName:KeyboardPrefsChangedNotification 
															object:[UIApplication sharedApplication].delegate];
		self.keyboardLabel.text = item;
	}
	[self.navigationController popToRootViewControllerAnimated:YES];
}

@end
