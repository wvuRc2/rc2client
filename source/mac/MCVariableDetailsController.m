//
//  MCVariableDetailsController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/8/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "MCVariableDetailsController.h"
#import "RCVariable.h"
#import "RCList.h"
#import "RCMSyntaxHighlighter.h"

@interface MCVariableDetailsController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSTableView *simpleTableView;
@property (nonatomic, weak) IBOutlet NSTableView *ssTableView;
@property (nonatomic, weak) IBOutlet NSTableView *listTableView;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *typeLabel;
@property (nonatomic, strong) IBOutlet NSTextView *functionTextView;
@property BOOL isSS;
@end

@implementation MCVariableDetailsController {
	NSInteger _contentWidth;
	BOOL _didInit;
}

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		_contentWidth = 200;
	}
	return self;
}

-(void)awakeFromNib
{
	if (!_didInit) {
		if (self.variable) {
			self.nameLabel.stringValue = self.variable.name;
			self.typeLabel.stringValue = self.variable.description;
			[self adjustForVariable];
		}
		_didInit=YES;
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
		case eVarType_Matrix:
			return YES;

		case eVarType_Array:
		case eVarType_Environment:
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
	@synchronized(self) {
	self.nameLabel.stringValue = self.variable.name;
	self.typeLabel.stringValue = self.variable.description;
	_isSS = NO;
	switch (self.variable.type) {
		case eVarType_Primitive:
		case eVarType_Factor:
			[self.tabView selectTabViewItemWithIdentifier:@"basic"];
			[self.simpleTableView reloadData];
			_contentWidth = 200;
			break;
		case eVarType_List:
			[self.tabView selectTabViewItemWithIdentifier:@"list"];
			[self.listTableView reloadData];
			if ([(RCList*)self.variable hasNames])
				[(NSTableColumn*)[self.listTableView tableColumnWithIdentifier:@"listhead"] setWidth:90];
			else
			[(NSTableColumn*)[self.listTableView tableColumnWithIdentifier:@"listhead"] setWidth:30];
			_contentWidth = 300;
			break;
		case eVarType_DataFrame:
		case eVarType_Matrix:
			_isSS = YES;
			[self.tabView selectTabViewItemWithIdentifier:@"dataFrame"];
			[self adjustForDataFrame];
			[self.ssTableView reloadData];
			break;
		case eVarType_Function:
			[self.tabView selectTabViewItemWithIdentifier:@"function"];
			self.functionTextView.string = @"";
			[self.functionTextView.textStorage appendAttributedString:[[RCMSyntaxHighlighter sharedInstance] syntaxHighlightCode:[NSAttributedString attributedStringWithString:self.variable.functionBody attributes:nil] ofType:@"R"]];
			_contentWidth = 500;
			break;
		case eVarType_Array:
		case eVarType_Environment:
		case eVarType_S3Object:
		case eVarType_S4Object:
		case eVarType_Unknown:
		case eVarType_Vector:
			break;
	}
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

-(NSSize)calculateContentSize:(NSSize)curSize
{
	if (_isSS) {
		NSSize sz = curSize;
		curSize.width = (self.ssTableView.tableColumns.count * 64) + 40; //colwidth, 20 margin on each side
	} else {
		curSize.width = _contentWidth;
	}
	return curSize;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.simpleTableView)
		return self.variable.count;
	if (tableView == self.listTableView)
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
	if (tableView == self.listTableView) {
		RCList *list = (RCList*)self.variable;
		if ([tableColumn.identifier isEqualToString:@"listhead"]) {
			NSTableCellView *hcell = [tableView makeViewWithIdentifier:@"listhead" owner:self];
			hcell.textField.stringValue = [NSString stringWithFormat:@"%ld. %@", row+1, [list nameAtIndex:row]];
			return hcell;
		} else {
			NSTableCellView *hcell = [tableView makeViewWithIdentifier:@"listitem" owner:self];
			hcell.textField.stringValue = [[list valueAtIndex:row] description];
			return hcell;
		}
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
