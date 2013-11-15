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
#import "RCSession.h"
#import "RCMSyntaxHighlighter.h"
#import "MCVariableDetailsController.h"

@interface MCVariableDisplayController () <NSTableViewDataSource, NSTableViewDelegate, MCVariableDetailsDelegate>
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
			dc.variableDelegate = self;
			[self.detailControllers addObject:dc];
			dc.view.frame = self.detailsContainerView.bounds;
			[self.detailsContainerView addSubview:dc.view];
			dc.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
			dc.variable = self.variable;
			[self adjustForVariable];
			self.nameLabel.backgroundColor = [NSColor clearColor];
		}
		_didInit=YES;
	}
}

-(MCVariableDisplayController*)dulicateController
{
	MCVariableDisplayController *dup = [[MCVariableDisplayController alloc] init];
	dup.session = self.session;
	dup.variable = self.variable;
	return dup;
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
		case eVarType_Environment:
		case eVarType_Matrix:
			return YES;

		case eVarType_Array:
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
	RCVariable *var = [[self currentDetailsController] variable];
	@synchronized(self) {
		self.nameLabel.stringValue = var.name;
		if ([var isKindOfClass:[RCList class]]) {
			self.listPathControl.pathComponentCells = @[[NSPathComponentCell pathCellWithTitle:var.name]];
			[self.listPathControl.pathComponentCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[obj setFont:[NSFont boldSystemFontOfSize:13]];
			}];
			self.nameLabel.hidden = YES;
		} else {
			self.listPathControl.hidden = YES;
		}
		if ([var isKindOfClass:[RCEnvironment class]]) {
			RCEnvironment *env = (RCEnvironment*)var;
			if (!env.hasValues) {
				[self.session requestListVariableData:env block:^(RCList *aList) {
					self.variable = aList;
					[[self currentDetailsController] setVariable:aList];
				}];
			}
		}
	}
}

-(IBAction)listPathClicked:(id)sender
{
	NSArray *pathCs = [self.listPathControl.pathComponentCells copy];
	ZAssert(pathCs.count == self.detailControllers.count, @"oopsie");
	NSPathComponentCell *cell = [self.listPathControl clickedPathComponentCell];
	if (pathCs.count < 2)
		return;
	if (cell != pathCs.lastObject) {
		//for now, just pop the top item off
		MCVariableDetailsController *oldTop = [self currentDetailsController];
		MCVariableDetailsController *newTop = self.detailControllers[self.detailControllers.count-2];
		NSRect oldFrame = oldTop.view.bounds;
		oldFrame.origin.x += self.view.bounds.size.width;
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.3];
//		[[NSAnimationContext currentContext] setCompletionHandler:^{
//			self.popover.contentSize = [newTop calculateContentSize:self.popover.contentSize];
//		}];
		[[oldTop.view animator] setFrame:oldFrame];
		[[newTop.view animator] setFrame:newTop.view.bounds];
		[NSAnimationContext endGrouping];
		[self.detailControllers removeLastObject];
		self.listPathControl.pathComponentCells = [pathCs arrayByRemovingObjectAtIndex:pathCs.count-1];
		//the following is a nasty hack as NSPathControl does not redraw after the above change.
		self.listPathControl.hidden = YES;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.listPathControl.hidden = NO;
		});
	}
}

-(void)showVariableDetails:(RCVariable *)variable
{
	MCVariableDetailsController *oldDc = [self currentDetailsController];
	MCVariableDetailsController *dc = [[MCVariableDetailsController alloc] init];
	dc.variableDelegate = self;
	[self.detailControllers addObject:dc];
	NSRect r = self.detailsContainerView.bounds;
	r.origin.x = r.size.width;
	dc.view.frame = r;
	dc.variable = variable;
	[self.detailsContainerView addSubview:dc.view];
	
	dc.view.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
#ifdef ANIM_DEBUG
	dc.view.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:dc.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.detailsContainerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:dc.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.detailsContainerView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
#endif
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.3];
	NSRect oldDestRect = oldDc.view.frame;
	oldDestRect.origin.x -= oldDestRect.size.width;
	[[oldDc.view animator] setFrame:oldDestRect];
	[[dc.view animator] setFrame:self.detailsContainerView.bounds];
#ifdef ANIM_DEBUG
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		self.popover.contentSize = [dc calculateContentSize:self.popover.contentSize];
	}];
#endif
	[NSAnimationContext endGrouping];

	if ([variable isKindOfClass:[RCList class]]) {
		RCList *newList = (RCList*)variable;
		if (!newList.hasValues) {
			[self.session requestListVariableData:newList block:^(RCList *aList) {
				dc.variable = aList;
			}];
		}
	}

	RCList *curList = (RCList*)oldDc.variable;
	NSString *sname = variable.name;
	if (curList.hasNames)
		sname = [curList nameAtIndex:[curList indexOfVariable:variable]];
	if (nil == sname)
		sname = [NSString stringWithFormat:@"[%ld]", [curList indexOfVariable:variable]];
	
	NSMutableArray *pathCs = [self.listPathControl.pathComponentCells mutableCopy];
	[pathCs addObject:[NSPathComponentCell pathCellWithTitle:sname]];
	self.listPathControl.pathComponentCells = pathCs;
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
