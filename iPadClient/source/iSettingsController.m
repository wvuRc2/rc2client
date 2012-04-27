//
//  iSettingsController.m
//  iPadClient
//
//  Created by Mark Lilback on 2/8/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "iSettingsController.h"
#import "AppConstants.h"
#import "ThemeEngine.h"
#import "Vyana-ios/AMNavigationTreeController.h"

enum { eTree_Theme, eTree_Keyboard };

@interface iSettingsController() {
	int _treeType;
}
@property (nonatomic, strong) AMNavigationTreeController *treeController;
@property (nonatomic, copy) NSArray *keyboards;
@property (nonatomic, copy) NSArray *themes;
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
		[myThemes removeObject:@"Custom"];
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
	ThemeEngine *te = [ThemeEngine sharedInstance];
	Theme *curTheme = te.currentTheme;
	self.themeLabel.text = curTheme.name;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self action:@selector(dismiss:)];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

-(IBAction)dismiss:(id)sender
{
	[self.containingPopover dismissPopoverAnimated:YES];
}

#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	if (section == 1)
		return 2;
	return 0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return self.passwordCell;
	} else if (indexPath.section == 1) {
		if (indexPath.row == 0)
			return self.keyboardCell;
		return self.themeCell;
	}
	return nil;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (0 == section)
		return @"Account";
	if (1 == section)
		return @"Settings";
	return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//the only ones we allow selection of are 1,0, 2,0, and 2.1
	if (indexPath.section == 1)
		return indexPath;
	if (indexPath.section == 0 && indexPath.row == 0)
		return indexPath;
	return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 1) {
			self.treeController = [[AMNavigationTreeController alloc] init];
			self.treeController.tracksSelectedItem=YES;
			self.treeController.delegate = (id)self;
			self.treeController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
			self.treeController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
		if (indexPath.row == 0) {
			_treeType = eTree_Keyboard;
			self.treeController.title = @"Select Keyboard";
			self.treeController.contentItems = self.keyboards;
			NSInteger k = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefKeyboardLayout];
			self.treeController.selectedItem = [self.keyboards objectAtIndex:k];
		} else {
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

@synthesize settingsTable;
@synthesize passwordCell;
@synthesize keyboardCell;
@synthesize themeCell;
@synthesize keyboardLabel;
@synthesize themeLabel;
@synthesize containingPopover;
@synthesize treeController;
@synthesize keyboards;
@synthesize themes;
@end
