//
//  VariableSpreadsheetController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "VariableSpreadsheetController.h"
#import "RCMatrix.h"
#import "SpreadsheetScroller.h"

@interface VariableSpreadsheetController () <SpreadsheetDataSource>
@property (nonatomic, weak) IBOutlet UIScrollView *headerView;
@property (nonatomic, weak) IBOutlet SpreadsheetScroller *dataView;
@property CGSize ssheetCellSize;
@end

@implementation VariableSpreadsheetController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.title = [(RCVariable*)self.variable name];
	self.dataView.dataSource = self;
	self.ssheetCellSize = CGSizeMake(80, 40);
	self.dataView.showRowHeaders = self.variable.rowNames.count > 0;
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

-(CGSize)contentSizeForViewInPopover
{
	return CGSizeMake(360, 600);
}


-(NSArray*)ssheetColumnTitles
{
	return [self.variable columnNames];
}

-(NSInteger)ssheetRowCount
{
	return [self.variable rowCount];
}

-(NSInteger)ssheetColumnCount
{
	return [self.variable colCount];
}

-(NSString*)ssheetContentForRow:(NSInteger)row column:(NSInteger)col
{
	if (col == -1)
		return [[[self.variable rowNames] objectAtIndex:row] description];
	return [self.variable valueAtRow:row column:col];
}

@end
