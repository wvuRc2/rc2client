//
//  RCMAddShareController.m
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMAddShareController.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCWorkspaceShare.h"
#import "ASIHTTPRequest.h"

@interface RCMAddShareController()
@property (nonatomic, strong) ASIHTTPRequest *currentRequest;
@property (nonatomic, strong) NSRecursiveLock *requestLock;
@end

@implementation RCMAddShareController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:@"RCMAddShareController" bundle:nil])) {
		self.requestLock = [[NSRecursiveLock alloc] init];
	}
	return self;
}

-(void)processSearchResults:(NSArray*)results
{
	NSMutableArray *users = [NSMutableArray array];
	for (NSDictionary *dict in results) {
		if (nil == [self.workspace.shares firstObjectWithValue:[dict objectForKey:@"id"] forKey:@"userId"])
		{
			NSMutableDictionary *md = [dict mutableCopy];
			NSString *fn = [NSString stringWithFormat:@"%@ (%@)", [md objectForKey:@"name"], [md objectForKey:@"login"]];
			[md setObject:fn forKey:@"fullname"];
			[users addObject:md];
		}
	}
	self.arrayController.content = users;
	[self.resultsTable reloadData];
}

-(IBAction)addShareForUser:(id)sender
{
	NSInteger row = [self.resultsTable rowForView:sender];
	self.changeHandler([[self.arrayController.arrangedObjects objectAtIndex:row] objectForKey:@"id"]);
	//remove from results
	[self.resultsTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationSlideUp|NSTableViewAnimationEffectFade];
	[self.arrayController removeObjectAtArrangedObjectIndex:row];
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
	self.currentRequest = [[Rc2Server sharedInstance] createUserSearchRequest:sstring];
	__block ASIHTTPRequest *req = self.currentRequest;
	__unsafe_unretained RCMAddShareController *blockSelf = self;
	[self.currentRequest setCompletionBlock:^{
		[blockSelf.requestLock lock];
		if (blockSelf.currentRequest == req) {
			NSString *respStr = [NSString stringWithUTF8Data:req.responseData];
			if (![[req.responseHeaders objectForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
				return;
			}
			NSDictionary *rsp = [respStr JSONValue];
			[blockSelf processSearchResults:[rsp objectForKey:@"users"]];
		}
		[blockSelf.requestLock unlock];
	}];
	[self.currentRequest setFailedBlock:^{
		//FIXME: do something
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
@synthesize workspace;
@synthesize changeHandler;
@end
