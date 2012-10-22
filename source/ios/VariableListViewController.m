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
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.session.variablesVisible = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	self.session.variablesVisible = NO;
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(360, 600);
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
	if (var.type == eVarType_Matrix) {
		VariableSpreadsheetController *ssheet = [[VariableSpreadsheetController alloc] init];
		ssheet.variable = var;
		[self.navigationController pushViewController:ssheet animated:YES];
	} else {
		VariableDetailViewController *detail = [[VariableDetailViewController alloc] init];
		detail.variable = var;
		[self.navigationController pushViewController:detail animated:YES];
	}
}

@end
