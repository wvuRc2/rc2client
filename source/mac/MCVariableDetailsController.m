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
@property (nonatomic, weak) IBOutlet NSTableView *ssTableView;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *typeLabel;
@property (nonatomic, strong) IBOutlet NSTextView *functionTextView;
@property BOOL isSS;
@end

@implementation MCVariableDetailsController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	if (self.variable) {
		self.nameLabel.stringValue = self.variable.name;
		self.typeLabel.stringValue = self.variable.description;
		[self adjustForVariable];
	}
}

-(BOOL)variableSupported:(RCVariable*)var
{
	switch (var.type) {
		case eVarType_Primitive:
		case eVarType_DataFrame:
		case eVarType_Function:
		case eVarType_Factor:
		case eVarType_List:
			return YES;

		case eVarType_Array:
		case eVarType_Environment:
		case eVarType_Matrix:
		case eVarType_S3Object:
		case eVarType_S4Object:
		case eVarType_Unknown:
		case eVarType_Vector:
			break;
	}
	return NO;
}

-(void)adjustForVariable
{
	self.nameLabel.stringValue = self.variable.name;
	_isSS = NO;
	switch (self.variable.type) {
		case eVarType_Primitive:
		case eVarType_List:
			[self.simpleTableView reloadData];
			break;
		case eVarType_DataFrame:
			_isSS = YES;
			[self.tabView selectTabViewItemWithIdentifier:@"dataFrame"];
			[self adjustForDataFrame];
			[self.ssTableView reloadData];
			break;
		case eVarType_Function:
			[self.tabView selectTabViewItemWithIdentifier:@"function"];
			self.functionTextView.string = self.variable.functionBody;
			break;
		case eVarType_Array:
		case eVarType_Environment:
		case eVarType_Factor:
		case eVarType_Matrix:
		case eVarType_S3Object:
		case eVarType_S4Object:
		case eVarType_Unknown:
		case eVarType_Vector:
			break;
	}
}

-(void)adjustForDataFrame
{
	NSInteger numCols = [self.ssData colCount] + 1; //plus header
	while (self.ssTableView.tableColumns.count > numCols)
		[self.ssTableView removeTableColumn:self.ssTableView.tableColumns.lastObject];
	for (NSInteger i=self.ssTableView.tableColumns.count; i < numCols; i++)
		[self.ssTableView addTableColumn:[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%ld", i]]];
	for (NSInteger i=1; i < numCols; i++) {
		NSTableColumn *col = [self.ssTableView.tableColumns objectAtIndex:i];
		col.width = 60;
		[[col headerCell] setStringValue:[[self.ssData columnNames] objectAtIndex:i-1]];
	}
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.simpleTableView)
		return self.variable.count;
	return [self.ssData rowCount];
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == self.simpleTableView) {
		NSTableCellView *cell = [tableView makeViewWithIdentifier:@"basic" owner:self];
		RCVariable *ivar = [self.variable valueAtIndex:row];
		cell.textField.stringValue = ivar.description ? ivar.description : @"<Unknown>";
		return cell;
	}
	BOOL isRowHead = [tableColumn.identifier isEqualToString:@"0"];
	NSInteger colNum = tableColumn.identifier.integerValue;
	NSTableCellView *cell = [tableView makeViewWithIdentifier:isRowHead ? @"ssHead" : @"ssValue" owner:self];
	if (isRowHead)
		cell.textField.stringValue = [[self.ssData rowNames] objectAtIndex:row];
	else
		cell.textField.stringValue = [self.ssData valueAtRow:row column:colNum-1];
	if (isRowHead)
		cell.backgroundStyle = NSBackgroundStyleRaised | NSBackgroundStyleDark;
	return cell;
}

-(id<RCSpreadsheetData>)ssData { return (id)_variable; }

-(void)setVariable:(RCVariable *)variable
{
	_variable = variable;
	[self adjustForVariable];
}

@end
