//
//  MCProjectShareController.m
//  Rc2Client
//
//  Created by Mark Lilback on 5/22/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import "MCProjectShareController.h"
#import "MCProjectShareCellView.h"
#import "Rc2Server.h"

@interface MCProjectShareController() <NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, weak) IBOutlet NSTableView *searchTable;
@property (nonatomic, weak) IBOutlet NSTableView *shareTable;
@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSArray *sharedUsers;
@property (nonatomic, strong) NSDictionary *selectedResult;
@property (nonatomic, strong) NSDictionary *selectedUser;
@property (assign) BOOL registeredNibs;
@end

@implementation MCProjectShareController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)awakeFromNib
{
	if (!self.registeredNibs) {
		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"MCProjectShareCellView" bundle:nil];
		[self.searchTable registerNib:nib forIdentifier:@"user"];
		[self.shareTable registerNib:nib forIdentifier:@"user"];
		self.registeredNibs = YES;
	}
}

-(void)viewDidMoveToWindow
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.view.window makeFirstResponder:self.searchField];
	});
}

-(IBAction)addUserToShareList:(id)sender
{
	
}

-(IBAction)removeUserFromShareList:(id)sender
{
	
}

-(IBAction)searchUsers:(id)sender
{
	NSString *ss = self.searchField.stringValue;
	if (nil == ss)
		ss = @"";
	if (ss.length < 1)
		return;
	NSDictionary *params = @{@"value":ss};
	[[Rc2Server sharedInstance] searchUsers:params completionHandler:^(BOOL success, id results) {
		if (success)
			[self processSearchResults:results];
		else
			Rc2LogWarn(@"user search failed:%@", results);
	}];
}

-(void)processSearchResults:(NSDictionary*)rsp
{
	if (![rsp[@"status"] intValue] == 0) {
		Rc2LogError(@"error searching users:%@", [rsp objectForKey:@"message"]);
		return;
	}
	NSArray *matches = [rsp objectForKey:@"users"];
	self.searchResults = matches;
	self.selectedUser = nil;
	[self.searchTable reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.searchTable)
		return self.searchResults.count;
	return self.sharedUsers.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	MCProjectShareCellView *view = (MCProjectShareCellView*)[tableView makeViewWithIdentifier:@"user" owner:self];
	if (tableView == self.searchTable)
		view.objectValue = [self.searchResults objectAtIndex:row];
	else
		view.objectValue = [self.sharedUsers objectAtIndex:row];
	return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger idx = [[aNotification object] selectedRow];
	if (aNotification.object == self.searchTable) {
		self.selectedResult = idx >= 0 ? self.searchResults[idx] : nil;
	} else {
		self.selectedUser = idx >= 0 ? self.sharedUsers[idx] : nil;
	}
}

@end
