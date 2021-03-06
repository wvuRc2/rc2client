//
//  VariableListViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "VariableListViewController.h"
#import "BasicVariableCell.h"
#import "RCSession.h"
#import "RCVariable.h"
#import "VariableDetailViewController.h"
#import "VariableSpreadsheetController.h"
#import "VariableListController.h"

@interface VariableListViewController ()
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *tableData;
@end

@implementation VariableListViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil])) {
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	UINib *nib = [UINib nibWithNibName:@"BasicVariableCell" bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:@"basicValueCell"];
	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refresh Variables"];
	[self.refreshControl addTarget:self action:@selector(forceRefresh) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.title = NSLocalizedString(@"Variables", @"");
	UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearVariables:)];
	self.navigationItem.rightBarButtonItem = clearButton;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	__weak UITableView *btable = self.tableView;
	[[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note)
	 {
		for (BasicVariableCell *cell in btable.visibleCells)
		{
			[cell updateFonts];
		}
	 }];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.session.variablesVisible = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[super setEditing:NO animated:NO];
	self.session.variablesVisible = NO;
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(360, 600);
}

-(IBAction)clearVariables:(id)sender
{
	[self.session executeScript:@"rm(list = ls())" scriptName:nil];
	[self forceRefresh];
}

-(void)forceRefresh
{
	[self.session forceVariableRefresh];
}

-(void)variablesUpdated
{
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:3];
	NSMutableArray *data = [NSMutableArray array];
	NSMutableArray *values = [NSMutableArray array];
	NSMutableArray *funcs = [NSMutableArray array];
	for (RCVariable *var in self.session.variables) {
		if (var.treatAsContainerType)
			[data addObject:var];
		else if (var.type == eVarType_Function)
			[funcs addObject:var];
		else
			[values addObject:var];
	}
	if (values.count > 0)
		[ma addObject: @{@"name": @"Values", @"data": values}];
	if (data.count > 0)
		[ma addObject: @{@"name": @"Data", @"data": data}];
	if (funcs.count > 0)
		[ma addObject: @{@"name": @"Functions", @"data": funcs}];
	self.tableData = ma;

	if (self.tableView.window != nil)
		[self.tableView reloadData];
	if (self.refreshControl.refreshing)
		[self.refreshControl endRefreshing];
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.tableData.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSDictionary *sec = [self.tableData objectAtIndex:section];
	return [[sec objectForKey:@"data"] count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	BasicVariableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicValueCell"];
	NSDictionary *section = [self.tableData objectAtIndex:indexPath.section];
	RCVariable *var = [[section objectForKey:@"data"] objectAtIndex:indexPath.row];
	cell.titleLabel.text = var.name;
	cell.valueLabel.text = var.description;
	return cell;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *section = [self.tableData objectAtIndex:indexPath.section];
	RCVariable *var = [[section objectForKey:@"data"] objectAtIndex:indexPath.row];
	[self.session executeScript:[NSString stringWithFormat:@"rm(%@)", var.name] scriptName:nil];
	[[section objectForKey:@"data"] removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 38;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self.tableData objectAtIndex:section] objectForKey:@"name"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *section = [self.tableData objectAtIndex:indexPath.section];
	RCVariable *var = [[section objectForKey:@"data"] objectAtIndex:indexPath.row];
	[self showVariableDetails:var];
}

@end
