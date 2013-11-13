//
//  MCVariableDisplayController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/8/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "MCVariableDisplayController.h"
#import "RCMAppConstants.h"
#import "RCVariable.h"
#import "RCList.h"
#import "RCMSyntaxHighlighter.h"
#import "MCVariableDetailsController.h"

@interface MCVariableDisplayController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, weak) IBOutlet NSView *detailsContainerView;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabel;
@property (nonatomic, weak) IBOutlet NSPathControl *listPathControl;
@property (nonatomic, strong) NSMutableArray *detailControllers;
@end

@implementation MCVariableDisplayController {
	BOOL _didInit;
}

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.detailControllers = [NSMutableArray arrayWithCapacity:4];
	}
	return self;
}

-(void)awakeFromNib
{
	if (!_didInit) {
		if (self.variable) {
			self.nameLabel.stringValue = self.variable.name;
			MCVariableDetailsController *dc = [[MCVariableDetailsController alloc] init];
			[self.detailControllers addObject:dc];
			dc.view.frame = self.detailsContainerView.bounds;
			[self.detailsContainerView addSubview:dc.view];
			dc.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
			dc.variable = self.variable;
			[self adjustForVariable];
		}
		_didInit=YES;
	}
}

-(MCVariableDetailsController*)currentDetailsController
{
	return self.detailControllers.lastObject;
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

-(void)animateToCorrectNameControl:(BOOL)isList
{
	self.nameLabel.alphaValue = isList ? 0 : 1;
	self.listPathControl.alphaValue = isList ? 1 : 0;
}

-(void)adjustForVariable
{
	RCVariable *var = [[self currentDetailsController] variable];
	@synchronized(self) {
		self.nameLabel.stringValue = var.name;
		if (var.type == eVarType_List) {
			self.listPathControl.pathComponentCells = @[[NSPathComponentCell pathCellWithTitle:var.name]];
			[self.listPathControl.pathComponentCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[obj setFont:[NSFont boldSystemFontOfSize:13]];
			}];
		}
		[self animateToCorrectNameControl:self.variable.type == eVarType_List];
	}
}

-(NSSize)calculateContentSize:(NSSize)curSize
{
	return [[self currentDetailsController] calculateContentSize:curSize];
}

-(void)setVariable:(RCVariable *)variable
{
	_variable = variable;
	[self currentDetailsController].variable = variable;
	[self adjustForVariable];
}

@end
