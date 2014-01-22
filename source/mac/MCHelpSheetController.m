//
//  MCHelpSheetController.m
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/14.
//  Copyright 2014 West Virginia University. All rights reserved.
//

#import "MCHelpSheetController.h"
#import "RCSession.h"

@interface MCHelpSheetController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, weak) IBOutlet NSTableView *topicTableView;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL validSelection;
@end

@implementation MCHelpSheetController
-(id)init
{
	self = [super initWithWindowNibName:@"MCHelpSheetController"];
	return self;
}

-(void)windowDidLoad
{
	self.topicTableView.doubleAction = @selector(doDisplay:);
	self.topicTableView.target = self;
	[self.topicTableView reloadData];
}

-(IBAction)doDisplay:(id)sender
{
	[self.window orderOut:self];
	self.handler(self, self.helpItems[self.selectedIndex]);
}

-(IBAction)doCancel:(id)sender
{
	[self.window orderOut:self];
	self.handler(self, nil);
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.helpItems.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return self.helpItems[row][kHelpItemTitle];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	self.selectedIndex = self.topicTableView.selectedRow;
	self.validSelection = self.selectedIndex != -1 && self.selectedIndex != NSNotFound;
}
@end
