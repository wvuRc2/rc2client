//
//  MCAdminController.m
//  Rc2Client
//
//  Created by Mark Lilback on 1/15/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import "MCAdminController.h"
#import "MCUserAdminController.h"

@interface MCAdminController () <NSOutlineViewDataSource,NSOutlineViewDelegate>
@property (nonatomic, weak) IBOutlet NSOutlineView *sourceList;
@property (nonatomic, weak) IBOutlet NSView *detailView;
@property (nonatomic, copy) NSArray *sourceItems;
@property (nonatomic, strong) MCUserAdminController *userController;
@end

@implementation MCAdminController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.sourceItems = @[
							 @{@"name":@"Users", @"nib":@"MCUserAdminController"},
							 @{@"name":@"Permissions"}
							];
	}
	return self;
}

-(void)viewDidMoveToWindow
{
	[super viewDidMoveToWindow];
	if (nil == self.userController)
		[self outlineViewSelectionDidChange:[NSNotification notificationWithName:@"nothing" object:nil]];
}

-(BOOL)usesToolbar { return YES; }

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.sourceItems.count;
//	if ([item isKindOfClass:[NSDictionary class]])
//		return [item count];
	return 0;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [[item objectForKey:@"children"] count];
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
//	if (nil == item)
		return self.sourceItems[index];
	return nil;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSView *view;
	switch (self.sourceList.selectedRow) {
		case 0:
			if (nil == self.userController)
				self.userController = [[MCUserAdminController alloc] init];
			view = self.userController.view;
			break;
	}
	while (self.detailView.subviews.count > 0)
		[self.detailView.subviews[0] removeFromSuperview];
	if (view) {
		[self.detailView addSubview:view];
		[self.detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
		[self.detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)]];
	}
}

-(NSView*)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView *view = [outlineView makeViewWithIdentifier:@"DataCell" owner:nil];
	view.textField.stringValue = item[@"name"];
	return view;
}

@end
