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
@property (nonatomic, strong) SendMessageViewController *composeController;
@property (nonatomic, copy) NSArray *messages;
@property (nonatomic, copy) NSArray *flagImages;
@property (nonatomic, assign) NSInteger selRowIdx;
@property (nonatomic, assign) NSInteger extraHeight;
@property (nonatomic, assign) NSInteger defaultHeight;
@property (nonatomic, strong) MessageListCell *currentSelection;
@property (nonatomic, strong) UIColor *selectedBG;
@property (nonatomic, strong) UIColor *normalBG;
@property (nonatomic, strong) id themeChangeNotice;
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
		id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *theme) {
			[blockSelf updateForNewTheme:theme];
		}];
		self.themeChangeNotice=tn;
		_didLoad=YES;
	}
	[[Rc2Server sharedInstance] syncMessages:^(BOOL success, id results) {
		if (success) {
			[blockSelf refreshMessages];
		}
	}];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
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
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	self.messages = [moc fetchObjectsForEntityName:@"RCMessage" withPredicate:nil sortDescriptors:ARRAY([NSSortDescriptor sortDescriptorWithKey:@"dateSent" ascending:NO])];
	[self.tableView reloadData];
}

-(IBAction)doComposeMessage:(id)sender
{
	__weak MessagesViewController *blockSelf = self;
	self.composeController = [[SendMessageViewController alloc] init];
	self.composeController.completionBlock = ^(NSInteger success) {
		[blockSelf dismissModalViewControllerAnimated:YES];
		blockSelf.composeController=nil;
	};
	self.composeController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self presentModalViewController:self.composeController animated:YES];
}

-(IBAction)doDeleteMessage:(id)sender
{
	[[Rc2Server sharedInstance] markMessageDeleted:[self.messages objectAtIndex:self.selRowIdx]];
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
		[[Rc2Server sharedInstance] markMessageRead:message];
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

@synthesize tableView=_tableView;
@synthesize imageView=_imageView;
@synthesize messages=_messages;
@synthesize flagImages=_flagImages;
@synthesize selectedBG=_selectedBG;
@synthesize currentSelection=_currentSelection;
@synthesize defaultHeight=_defaultHeight;
@synthesize themeChangeNotice=_themeChangeNotice;
@synthesize selRowIdx=_selRowIdx;
@synthesize extraHeight=_extraHeight;
@synthesize normalBG=_normalBG;
@synthesize composeController=_composeController;

@end
