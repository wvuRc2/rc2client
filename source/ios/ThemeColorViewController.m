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
#import "MAKVONotificationCenter.h"

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
	
	CustomTheme *theme = [[ThemeEngine sharedInstance] customTheme];
	self.colorEntries = [theme.colorEntries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	//select one by default so there is always a selection
	self.selectedEntry = [self.colorEntries firstObject];
	[self updateDetails];
	
	self.picker = [[ColorPickerController alloc] initWithColor:self.selectedEntry.color andTitle:self.selectedEntry.name];
	self.picker.defaultViewRect = self.pickerPlaceholder.bounds;
	[self addChildViewController:self.picker];
	[self.pickerPlaceholder addSubview:self.picker.view];
	[self.picker didMoveToParentViewController:self];
	[self observeTarget:self.picker keyPath:@"selectedColor" selector:@selector(pickerValueDidChange:) userInfo:nil options:NSKeyValueObservingOptionNew];
	
	UINib *nib = [UINib nibWithNibName:@"ThemeColorCell" bundle:nil];
	[self.colorTable registerNib:nib forCellReuseIdentifier:@"colorCell"];
}

-(IBAction)save:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	CustomTheme *theme = [[ThemeEngine sharedInstance] customTheme];
	[theme save];
	if (self.completionBlock)
		self.completionBlock();
}

-(IBAction)cancel:(id)sender
{
	//revert all changes
	for (ThemeColorEntry *entry in self.colorEntries)
		[entry setColor:entry.originalColor];
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateDetails
{
	self.selName.text = self.selectedEntry.name;
	self.picker.selectedColor = self.selectedEntry.color;
}

-(void)pickerValueDidChange:(MAKVONotification *)note
{
	NSString *newStr = [self.picker.selectedColor hexString];
	if ([newStr isEqualToString:[self.selectedEntry.color hexString]])
		return;
	self.selectedEntry.color = self.picker.selectedColor;
	[[self cellForCurrentEntry] setColorEntry:self.selectedEntry];
}

-(ThemeColorCell*)cellForCurrentEntry
{
	NSInteger idx = [self.colorEntries indexOfObject:self.selectedEntry];
	return (ThemeColorCell*)[self.colorTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
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


