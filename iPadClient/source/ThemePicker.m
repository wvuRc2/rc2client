//
//  ThemePicker.m
//  iPadClient
//
//  Created by Mark Lilback on 9/6/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "ThemePicker.h"
#import "ThemeEngine.h"

@implementation ThemePicker
@synthesize picker;
@synthesize customUrlField;

- (id)init
{
	return [super initWithNibName:@"ThemePicker" bundle:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	ThemeEngine *te = [ThemeEngine sharedInstance];
	NSArray *allthemes = te.allThemes;
	Theme *curTheme = te.currentTheme;
	NSInteger idx = [allthemes indexOfObject:curTheme];
	[self.picker selectRow:idx inComponent:0 animated:NO];
	self.customUrlField.text = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefCustomThemeURL];
}

- (void)viewDidUnload
{
	[self setPicker:nil];
	[self setCustomUrlField:nil];
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)dealloc
{
	self.picker=nil;
	[customUrlField release];
	[super dealloc];
}

- (IBAction)doCancel:(id)sender
{
	if ([self respondsToSelector:@selector(presentingViewController)])
		[self.presentingViewController dismissModalViewControllerAnimated:YES];
	else
		[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction)doDone:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:self.customUrlField.text forKey:kPrefCustomThemeURL];
	Theme *th = [[[ThemeEngine sharedInstance] allThemes] objectAtIndex:[self.picker selectedRowInComponent:0]];
	[[ThemeEngine sharedInstance] setCurrentTheme:th];
	if ([self respondsToSelector:@selector(presentingViewController)])
		[self.presentingViewController dismissModalViewControllerAnimated:YES];
	else
		[self.parentViewController dismissModalViewControllerAnimated:YES];	
}

#pragma mark - picker view

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [[ThemeEngine sharedInstance].allThemes count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [[[ThemeEngine sharedInstance].allThemes objectAtIndex:row] name];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 44;
}
@end

