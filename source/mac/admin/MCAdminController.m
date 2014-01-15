//
//  MCAdminController.m
//  Rc2Client
//
//  Created by Mark Lilback on 1/15/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import "MCAdminController.h"

@interface MCAdminController () <NSOutlineViewDataSource,NSOutlineViewDelegate>
@property (nonatomic, weak) IBOutlet NSOutlineView *sourceList;
@property (nonatomic, weak) IBOutlet NSView *detailView;
@property (nonatomic, copy) NSArray *sourceItems;
@end

@implementation MCAdminController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.sourceItems = @[@"Users",@"Permissions",@"Courses"];
	}
	return self;
}

-(BOOL)usesToolbar { return YES; }

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.sourceItems.count;
	if ([item isKindOfClass:[NSDictionary class]])
		return [item count];
	return 0;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isKindOfClass:[NSDictionary class]];
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (nil == item)
		return self.sourceItems[index];
	return nil;
}

-(NSView*)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView *view = [outlineView makeViewWithIdentifier:@"DataCell" owner:nil];
	view.textField.stringValue = item;
	return view;
}

@end
