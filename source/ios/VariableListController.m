//
//  VariableListController.m
//  Rc2Client
//
//  Created by Mark Lilback on 11/11/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "VariableListController.h"
#import "BasicVariableCell.h"

@interface VariableListController ()

@end

@implementation VariableListController
-(id)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	UINib *nib = [UINib nibWithNibName:@"BasicVariableCell" bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:@"basicValueCell"];
	self.navigationItem.title = self.listVariable.name;
	if (self.navigationItem.title.length < 1)
		self.navigationItem.title = self.listVariable.fullyQualifiedName;
	__weak VariableListController *bself = self;
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
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.listVariable.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCVariable *aVar = [self.listVariable valueAtIndex:indexPath.row];
	BasicVariableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicValueCell"];
	if ([self.listVariable isKindOfClass:[RCEnvironment class]])
		cell.titleLabel.text = [self.listVariable nameAtIndex:indexPath.row];
	else
		cell.titleLabel.text = [NSString stringWithFormat:@"%ld. %@", indexPath.row+1, [self.listVariable nameAtIndex:indexPath.row]];
	cell.valueLabel.text = [aVar description];
	cell.titleWidthConstraint.constant = self.listVariable.hasNames ? 100 : 30;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCVariable *var = [self.listVariable valueAtIndex:indexPath.row];
	[self showVariableDetails:var];
}

-(void)setListVariable:(RCList *)listVariable
{
	_listVariable = listVariable;
	[self.tableView reloadData];
}
@end
