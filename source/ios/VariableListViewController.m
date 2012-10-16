//
//  VariableListViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "VariableListViewController.h"
#import "BasicVariableCell.h"

@interface VariableListViewController ()
@property (nonatomic, weak) IBOutlet UITableView *tableView;
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
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(320, 400);
}

-(void)variablesUpdated
{
	[self.tableView reloadData];
}

#pragma mark - table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	BasicVariableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicValueCell"];
	cell.titleLabel.text = @"A Variable";
	cell.valueLabel.text = @"x,y";
	return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Values";
}

@end
