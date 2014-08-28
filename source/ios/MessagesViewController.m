//
//  MessagesViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "MessagesViewController.h"
#import "ThemeEngine.h"
#import "MessageListCell.h"
#import "RCMessage.h"
#import "Rc2Server.h"
#import "SendMessageViewController.h"

@interface MessagesViewController () <UITableViewDelegate,UITableViewDataSource> {
	BOOL _didLoad;
}
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIButton *composeButton;
@property (nonatomic, strong) SendMessageViewController *composeController;
@property (nonatomic, copy) NSArray *messages;
@property (nonatomic, copy) NSArray *flagImages;
@property (nonatomic, assign) NSInteger selRowIdx;
@property (nonatomic, assign) NSInteger extraHeight;
@property (nonatomic, assign) NSInteger defaultHeight;
@property (nonatomic, strong) MessageListCell *currentSelection;
@property (nonatomic, strong) UIColor *selectedBG;
@property (nonatomic, strong) UIColor *normalBG;
@end

@implementation MessagesViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		self.selRowIdx=-1;
		self.defaultHeight=-1;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	__weak MessagesViewController *blockSelf = self;
	if (!_didLoad) {
		Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
		NSIndexPath *ip = [self.tableView indexPathForSelectedRow];
		if (ip)
			[self.tableView deselectRowAtIndexPath:ip animated:NO];
		UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 40)];
		self.tableView.tableHeaderView = v;
		[self updateForNewTheme:theme];
		[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
			[blockSelf updateForNewTheme:theme];
		}];
		self.tableView.autoresizingMask=0;
		self.composeButton.autoresizingMask=0;
		if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
			self.tableView.frame = CGRectMake(134, 147, 500, 718);
			self.composeButton.frame = CGRectMake(134, CGRectGetMaxY(self.tableView.frame) + 8, 87, 37);
		}
		_didLoad=YES;
	}
	[RC2_SharedInstance() syncMessages:^(BOOL success, id results) {
		if (success) {
			[blockSelf refreshMessages];
		}
	}];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	CGRect newFrame = CGRectMake(262, 147, 500, 454);
	CGRect btnFrame = CGRectMake(262, 609, 87, 37);
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		newFrame.origin.x = 134;
		newFrame.size.height = 718;
		btnFrame.origin.x = 134;
		btnFrame.origin.y = CGRectGetMaxY(newFrame) + 8;
	}
	[UIView animateWithDuration:duration animations:^{
		self.tableView.frame = newFrame;
		self.composeButton.frame = btnFrame;
	} completion:^(BOOL finished) {
		[self.tableView reloadData];
	}];
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	NSArray *colors = [theme.themeColors objectForKey:@"PriorityColors"];
	UIImage *img = [UIImage imageNamed:@"flag"];
	NSMutableArray *imgs = [NSMutableArray array];
	for (NSString *aStr in colors) {
		UIImage *newImage = [img imageTintedWithColor:[UIColor colorWithHexString:aStr]];
		[imgs addObject:newImage];
	}
	self.flagImages = imgs;
	self.tableView.layer.backgroundColor = [theme colorForKey:@"MessageBackground"].CGColor;
	self.view.backgroundColor = [theme colorForKey:@"MessageCenterBackground"];
	[self.view setNeedsDisplay];
}

-(void)refreshMessages
{
	self.messages = [RCMessage MR_findAllSortedBy:@"dateSent" ascending:NO];
	[self.tableView reloadData];
}

-(IBAction)doComposeMessage:(id)sender
{
	__weak MessagesViewController *blockSelf = self;
	self.composeController = [[SendMessageViewController alloc] init];
	self.composeController.completionBlock = ^(NSInteger success) {
		[blockSelf dismissViewControllerAnimated:YES completion:nil];
		blockSelf.composeController=nil;
	};
	self.composeController.priorityImages = self.flagImages;
	self.composeController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self presentViewController:self.composeController animated:YES completion:nil];
}

-(IBAction)doDeleteMessage:(id)sender
{
	[RC2_SharedInstance() markMessageDeleted:[self.messages objectAtIndex:self.selRowIdx]];
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
		//		oldSelectedCell.view.backgroundColor = self.normalBG;
		[oldSelectedCell setIsSelected:NO];
		oldSelectedCell.deleteButton.hidden = YES;
	}
	//	newSelCell.view.backgroundColor = self.selectedBG;
	[newSelCell setIsSelected:YES];
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

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	MessageListCell *cell = [MessageListCell cellForTableView:aTableView];
	if (nil == cell.priorityImages) {
		cell.priorityImages = self.flagImages;
		[cell.deleteButton addTarget:self action:@selector(doDeleteMessage:) forControlEvents:UIControlEventTouchUpInside];
	}
	if (self.defaultHeight < 0)
		self.defaultHeight = cell.defaultCellHeight;
	CGFloat eh = [cell setMessage:[self.messages objectAtIndex:row] 
						 selected:cell == self.currentSelection];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.deleteButton.hidden=YES;
	cell.clipsToBounds=YES;
	cell.opaque = NO;
	if (cell == self.currentSelection) {
		cell.deleteButton.hidden=NO;
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

-(void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	MessageListCell *newCell = (MessageListCell*)[aTableView cellForRowAtIndexPath:indexPath];
	[self setSelectedCell:newCell deselectedCell:self.currentSelection];
	self.currentSelection = newCell;
	RCMessage *message = [self.messages objectAtIndex:indexPath.row];
	self.extraHeight = [newCell calculateHeightWithBody:message.body];
	if (nil == message.dateRead)
		[RC2_SharedInstance() markMessageRead:message];
	if (nil == indexPath)
		self.selRowIdx = -1;
	else
		self.selRowIdx = indexPath.row;
	[aTableView beginUpdates];
	[aTableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == self.selRowIdx)
		return self.extraHeight;
	return 113;
}
@end
