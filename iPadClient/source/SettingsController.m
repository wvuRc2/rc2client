//
//  SettingsController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "SettingsController.h"
#import "AppConstants.h"

@implementation SettingsController

- (id)init
{
    self = [super initWithNibName:@"SettingsController" bundle:nil];
    if (self) {
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

-(void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.leftySwitch.on = [defaults boolForKey:kPrefLefty];
}

#pragma mark - actions

-(IBAction)doClose:(id)sender
{
	if ([self respondsToSelector:@selector(presentingViewController)])
		[self.presentingViewController dismissModalViewControllerAnimated:YES];
	else
		[self.parentViewController dismissModalViewControllerAnimated:YES];
}

-(IBAction)valueChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (sender == self.leftySwitch) {
		[defaults setBool:self.leftySwitch.on forKey:kPrefLefty];
		[[NSNotificationCenter defaultCenter] postNotificationName:KeyboardPrefsChangedNotification 
															 object:[UIApplication sharedApplication].delegate];
	}
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.leftyCell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Settings";
}

#pragma mark - synthesizers

@synthesize settingsTable;
@synthesize leftyCell;
@synthesize leftySwitch;
@end
