//
//  MCVariableDetailsController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/8/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "MCVariableDetailsController.h"
#import "RCVariable.h"

@interface MCVariableDetailsController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSTableView *simpleTableView;
@end

@implementation MCVariableDetailsController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)adjustForVariable
{
	[self.simpleTableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 2;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cell = [tableView makeViewWithIdentifier:@"basic" owner:self];
	if (row == 0)
		cell.textField.stringValue = self.variable.name;
	else
		cell.textField.stringValue = self.variable.description;
	return cell;
}

-(void)setVariable:(RCVariable *)variable
{
	_variable = variable;
	[self adjustForVariable];
}

@end
