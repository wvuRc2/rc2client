//
//  ThemeColorViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ThemeColorViewController.h"
#import "ThemeColorEntry.h"
#import "ThemeColorCell.h"
#import "ThemeEngine.h"
#import "ColorPickerController.h"

@interface ThemeColorViewController () <UITableViewDataSource,UITableViewDelegate>
@property (weak) IBOutlet UITableView *colorTable;
@property (copy) NSArray *colorEntries;
@property (weak) IBOutlet UIView *pickerPlaceholder;
@property (weak) IBOutlet UILabel *selName;
@property (weak) ThemeColorEntry *selectedEntry;
@property (strong) ColorPickerController *picker;
@end

@implementation ThemeColorViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	NSMutableArray *a = [[NSMutableArray alloc] init];
	for (NSString *aKey in [[ThemeEngine sharedInstance] allColorKeys]) {
		ThemeColorEntry *entry = [[ThemeColorEntry alloc] initWithName:aKey color:[theme colorForKey:aKey]];
		[a addObject:entry];
	}
	self.colorEntries = a;
	//select one by default so there is always a selection
	self.selectedEntry = [a firstObject];
	[self updateDetails];
	
	self.picker = [[ColorPickerController alloc] initWithColor:self.selectedEntry.color andTitle:self.selectedEntry.name];
	self.picker.defaultViewRect = self.pickerPlaceholder.bounds;
	[self addChildViewController:self.picker];
	[self.pickerPlaceholder addSubview:self.picker.view];
	[self.picker didMoveToParentViewController:self];
	
	UINib *nib = [UINib nibWithNibName:@"ThemeColorCell" bundle:nil];
	[self.colorTable registerNib:nib forCellReuseIdentifier:@"colorCell"];
}

-(IBAction)save:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateDetails
{
	self.selName.text = self.selectedEntry.name;
	self.picker.selectedColor = self.selectedEntry.color;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.colorEntries count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ThemeColorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"colorCell"];
	cell.colorEntry = [self.colorEntries objectAtIndex:indexPath.row];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedEntry = [self.colorEntries objectAtIndex:indexPath.row];
	[self updateDetails];
}

@end


