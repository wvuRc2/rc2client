//
//  RCMUserSearchPopupController.m
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMUserSearchPopupController.h"
#import "Rc2Server.h"

@interface RCMUserSearchPopupController()
@property (copy) NSString *requestId;
@property (nonatomic, strong) NSRecursiveLock *requestLock;
@end

@implementation RCMUserSearchPopupController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.requestLock = [[NSRecursiveLock alloc] init];
		self.searchType = @"all";
	}
	return self;
}

-(void)processSearchResults:(NSArray*)results
{
	NSMutableArray *users = [NSMutableArray array];
	for (NSDictionary *dict in results) {
		if (self.showUserHandler == nil || self.showUserHandler([dict objectForKey:@"id"])) {
			NSMutableDictionary *md = [dict mutableCopy];
			NSString *fn = [NSString stringWithFormat:@"%@ (%@)", [md objectForKey:@"name"], [md objectForKey:@"login"]];
			[md setObject:fn forKey:@"fullname"];
			[users addObject:md];
		}
	}
	self.arrayController.content = users;
	[self.resultsTable reloadData];
}

-(IBAction)selectUser:(id)sender
{
	NSInteger row = [self.resultsTable rowForView:sender];
	self.selectUserHandler([[self.arrayController.arrangedObjects objectAtIndex:row] objectForKey:@"id"]);
	if (self.removeSelectedUserFromList) {
		[self.resultsTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationSlideUp|NSTableViewAnimationEffectFade];
		[self.arrayController removeObjectAtArrangedObjectIndex:row];
	}
}

-(IBAction)performSearch:(id)sender
{
	NSString *sstring = self.searchField.stringValue;
	if ([sstring length] < 1) {
		self.arrayController.content = [NSArray array];
		[self.resultsTable reloadData];
		return;
	}
	[self.requestLock lock];
	NSString *rid = [NSString stringWithUUID];
	self.requestId = rid;
	__weak RCMUserSearchPopupController *bself = self;
	[[Rc2Server sharedInstance] searchUsers:@{@"type":self.searchType, @"value":sstring} completionHandler:^(BOOL success, id results)
	{
		[bself.requestLock lock];
		//only if we are the most recent request
		if ([bself.requestId isEqualToString:rid]) {
			[bself processSearchResults:[results objectForKey:@"users"]];
		}
		[bself.requestLock unlock];
	}];
	[self.requestLock unlock];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	return [self.arrayController.arrangedObjects count];
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *view = [tableView makeViewWithIdentifier:@"cell" owner:self];
	view.objectValue = [self.arrayController.arrangedObjects objectAtIndex:row];
	return view;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

@end
