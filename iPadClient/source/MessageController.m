//
//  MessageController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MessageController.h"
#import "MessageListCell.h"
#import "Rc2Server.h"
#import "RCMessage.h"

@interface MessageController()
@property (nonatomic, copy) NSArray *flagImages;
@property (nonatomic, assign) NSInteger selRowIdx;
@property (nonatomic, assign) NSInteger extraHeight;
@property (nonatomic, assign) NSInteger defaultHeight;
@property (nonatomic, assign) MessageListCell *currentSelection;
@property (nonatomic, retain) UIColor *selectedBG;
@property (nonatomic, retain) UIColor *normalBG;
-(void)setSelectedCell:(MessageListCell*)newSelCell deselectedCell:(MessageListCell*)oldSelectedCell;
@end

@implementation MessageController

-(id)init
{
	if ((self = [super init])) {
		[[NSBundle mainBundle] loadNibNamed:@"MessageController" owner:self options:nil];
		self.selRowIdx=-1;
		self.defaultHeight=-1;
	}
	return self;
}

-(void)dealloc
{
	self.selectedBG=nil;
	self.normalBG=nil;
	self.flagImages=nil;
	self.messages=nil;
	[super dealloc];
}

-(void)viewDidLoad
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultTheme" ofType:@"plist"]];
	NSArray *colors = [dict objectForKey:@"PriorityColors"];
	UIImage *img = [UIImage imageNamed:@"flag"];
	NSMutableArray *imgs = [NSMutableArray array];
	for (NSString *aStr in colors) {
		UIImage *newImage = [img imageTintedWithColor:[UIColor colorWithHexString:aStr]];
		[imgs addObject:newImage];
	}
	self.flagImages = imgs;
	self.normalBG = [UIColor colorWithHexString:@"cccccc"];
	self.selectedBG = [UIColor colorWithHexString:@"eeeeee"];
	NSIndexPath *ip = [self.tableView indexPathForSelectedRow];
	if (ip)
		[self.tableView deselectRowAtIndexPath:ip animated:NO];
}

-(IBAction)doDone:(id)sender
{
	
}

-(IBAction)doDeleteMessage:(id)sender
{
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.selRowIdx inSection:0]]
						  withRowAnimation:UITableViewRowAnimationFade];
	self.messages = [self.messages arrayByRemovingObjectAtIndex:self.selRowIdx];
	[self.tableView endUpdates];
	self.selRowIdx = -1;
	self.currentSelection = nil;
}

-(void)setSelectedCell:(MessageListCell*)newSelCell deselectedCell:(MessageListCell*)oldSelectedCell
{
	if (nil != oldSelectedCell) {
		oldSelectedCell.view.backgroundColor = self.normalBG;
		oldSelectedCell.deleteButton.hidden = YES;
	}
	newSelCell.view.backgroundColor = self.selectedBG;
	newSelCell.deleteButton.hidden = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	MessageListCell *cell = [MessageListCell cellForTableView:tableView];
	if (nil == cell.priorityImages) {
		cell.priorityImages = self.flagImages;
		[cell.deleteButton addTarget:self action:@selector(doDeleteMessage:) forControlEvents:UIControlEventTouchUpInside];
	}
	if (self.defaultHeight < 0)
		self.defaultHeight = cell.defaultCellHeight;
	CGFloat eh = [cell setMessage:[self.messages objectAtIndex:row] 
								  selected:cell == self.currentSelection];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.view.layer.cornerRadius = 18;
	cell.deleteButton.hidden=YES;
	cell.view.layer.borderColor = [UIColor blackColor].CGColor;
	cell.view.layer.borderWidth = 1;
	cell.view.backgroundColor = [UIColor colorWithHexString:@"#cccccc"];
	cell.clipsToBounds=YES;
	cell.backgroundColor = [UIColor clearColor];
	cell.opaque = NO;
	if (cell == self.currentSelection) {
		cell.deleteButton.hidden=NO;
		cell.view.backgroundColor = [UIColor colorWithHexString:@"#eeeeee"];
		self.extraHeight = eh;
	}
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (nil == indexPath)
		self.selRowIdx = -1;
	else
		self.selRowIdx = indexPath.row;
	return indexPath;
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageListCell *newCell = (MessageListCell*)[tableView cellForRowAtIndexPath:indexPath];
	[self setSelectedCell:newCell deselectedCell:self.currentSelection];
	self.currentSelection = newCell;
	RCMessage *message = [self.messages objectAtIndex:indexPath.row];
	self.extraHeight = [newCell calculateHeightWithBody:message.body];
	if (nil == message.dateRead)
		[[Rc2Server sharedInstance] markMessageRead:message];
	if (nil == indexPath)
		self.selRowIdx = -1;
	else
		self.selRowIdx = indexPath.row;
	[tableView beginUpdates];
	[tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == self.selRowIdx)
			return self.extraHeight;
	return 113;
}


@synthesize view;
@synthesize tableView;
@synthesize imageView;
@synthesize flagImages;
@synthesize messages;
@synthesize selRowIdx;
@synthesize currentSelection;
@synthesize selectedBG;
@synthesize normalBG;
@synthesize extraHeight;
@synthesize defaultHeight;
@end
