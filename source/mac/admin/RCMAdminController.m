//
//  RCMAdminController.m
//  Rc2Client
//
//  Created by Mark Lilback on 3/21/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "RCMAdminController.h"
#import "MCUserAdminController.h"
#import "RCMRolePermController.h"
#import "MCMainWindowController.h"
#import "RCMCourseAdminController.h"

@interface RCMAdminController () <NSTabViewDelegate>
@property (weak) IBOutlet NSTabView *tabView;
@property (strong) AMViewController *currentController;
@property (strong) NSArray *controllers;
@end

@implementation RCMAdminController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	self.controllers = @[[[MCUserAdminController alloc] init], [[RCMRolePermController alloc] init],
					  [[RCMCourseAdminController alloc] init]];
	self.currentController = [self.controllers firstObject];
	[[self.tabView tabViewItemAtIndex:0] setView:self.currentController.view];
	[self.tabView selectTabViewItemAtIndex:0];
}

-(void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSInteger idx = [tabView indexOfTabViewItem:tabViewItem];
	self.currentController = [self.controllers objectAtIndex:idx];
	tabViewItem.view = self.currentController.view;
}

-(IBAction)navigateBack:(id)sender
{
	id controller = [TheApp valueForKeyPath:@"delegate.mainWindowController"];
	[controller doBackToMainView:sender];
}
@end
