//
//  RCMUserSearchPopupController.m
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "RCMUserSearchPopupController.h"
#import "Rc2Server.h"
#import "ASIHTTPRequest.h"

@interface RCMUserSearchPopupController()
@property (nonatomic, strong) ASIHTTPRequest *currentRequest;
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
	self.currentRequest = [[Rc2Server sharedInstance] createUserSearchRequest:sstring searchType:self.searchType];
	__block ASIHTTPRequest *req = self.currentRequest;
	__unsafe_unretained RCMUserSearchPopupController *blockSelf = self;
	[self.currentRequest setCompletionBlock:^{
		[blockSelf.requestLock lock];
		if (blockSelf.currentRequest == req) {
			NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
			NSDictionary *rsp = [respStr JSONValue];
			if (rsp)
				[blockSelf processSearchResults:[rsp objectForKey:@"users"]];
		}
		[blockSelf.requestLock unlock];
	}];
	[self.currentRequest setFailedBlock:^{
		Rc2LogWarn(@"error sending user search request");
	}];
	[self.currentRequest startAsynchronous];
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

@synthesize searchField;
@synthesize resultsTable;
@synthesize arrayController;
@synthesize currentRequest;
@synthesize requestLock;
@synthesize selectUserHandler;
@synthesize showUserHandler;
@synthesize searchType=_searchType;
@synthesize removeSelectedUserFromList=_removeSelectedUserFromList;
@end
