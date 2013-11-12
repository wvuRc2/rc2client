//
//  VariableDetailViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "VariableDetailViewController.h"
#import "RCVariable.h"
#import "FunctionVariableSummaryCell.h"

@interface VariableDetailViewController ()

@end

@implementation VariableDetailViewController

-(id)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.title = self.variable.name;
	UINib *nib = [UINib nibWithNibName:@"FunctionVariableSummaryCell" bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:@"function"];
	__weak VariableDetailViewController *bself = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note)
	{
		[bself.tableView reloadData];
	}];
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(360, 600);
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.variable.isPrimitive || self.variable.isFactor)
		return 2;
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1) {
		return self.variable.count;
	}
	return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell=nil;
	if (indexPath.section == 0) {
		if (_variable.type == eVarType_Function) {
			cell = [tableView dequeueReusableCellWithIdentifier:@"function"];
			[(FunctionVariableSummaryCell*)cell setVariable:self.variable];
			[(FunctionVariableSummaryCell*)cell updateFonts];
		} else {
			//summary cell
			cell = [tableView dequeueReusableCellWithIdentifier:@"summary"];
			if (nil == cell)
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"summary"];
			cell.textLabel.text = self.variable.name;
			cell.detailTextLabel.text = self.variable.description;
			cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
			cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
		}
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"dvalue"];
		if (nil == cell)
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dvalue"];
		id val=nil;
		val = [self.variable valueAtIndex:indexPath.row];
		cell.textLabel.text = [val description];
		cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	}
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		switch (_variable.type) {
			case eVarType_Function:
				return 297;
			default:
				;
		}
	}
	return 44;
}

-(void)setVariable:(RCVariable *)variable
{
	_variable = variable;
	[self.tableView reloadData];
}
@end
