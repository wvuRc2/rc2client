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

@interface ThemeColorViewController ()
@property (weak) IBOutlet UITableView *colorTable;
@property (copy) NSArray *colorEntries;
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

@end
