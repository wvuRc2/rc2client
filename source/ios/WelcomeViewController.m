//
//  WelcomeViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "WelcomeViewController.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "NotificationCell.h"
#import "PHRefreshGestureRecognizer.h"

@interface WelcomeViewController ()
@property (nonatomic, strong) IBOutlet UITableView *noteTable;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation WelcomeViewController

- (id)init
{
	self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (self) {
		self.notes = [NSMutableArray arrayWithCapacity:10];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:RC2NotificationsReceivedNotification object:nil];
		self.dateFormatter = [[NSDateFormatter alloc] init];
		self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
		self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	PHRefreshGestureRecognizer *gr = [[PHRefreshGestureRecognizer alloc] initWithTarget:self action:@selector(pullToRefresh:)];
	[self.noteTable addGestureRecognizer:gr];
	self.noteTable.autoresizingMask = 0;
	if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
		self.noteTable.frame = CGRectMake(134, 90, 500, 800);
	}
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	CGRect newFrame = CGRectMake(262, 90, 500, 460);
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
		newFrame.origin.x = 134;
		newFrame.size.height = 800;
	}
	[UIView animateWithDuration:duration animations:^{
		self.noteTable.frame = newFrame;
	} completion:^(BOOL finished) {
		[self.noteTable reloadData];
	}];
}

-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
	return UIBarPositionTopAttached;
}


#pragma mark - meat & potatos

-(void)pullToRefresh:(UIGestureRecognizer*)recog
{
	if (recog.state == UIGestureRecognizerStateRecognized) {
		[self reloadNotifications];
	}
}

-(void)reloadNotifications
{
	__weak WelcomeViewController *bself = self;
	[RC2_SharedInstance() requestNotifications:^(BOOL success, id results) {
		bself.noteTable.refreshGestureRecognizer.refreshState = PHRefreshIdle;
		if (success) {
			NSDictionary *d = results;
			if ([d objectForKey:@"status"] && [[d objectForKey:@"status"] intValue] == 0) {
				[bself.notes removeAllObjects];
				[bself.notes addObjectsFromArray:[d objectForKey:@"notes"]];
				[bself.noteTable reloadData];
			}
		} else {
			Rc2LogWarn(@"error fetching notifications:%@", results);
		}
	}];
}

-(void)notesLoaded:(NSNotification*)notif
{
	[self.notes removeAllObjects];
	[self.notes addObjectsFromArray:[notif.userInfo objectForKey:@"notes"]];
	[self.noteTable reloadData];
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.noteTable.layer.backgroundColor = [theme colorForKey:@"MessageBackground"].CGColor;
	[self.view setNeedsDisplay];
}

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.notes.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NotificationCell *cell = [NotificationCell cellForTableView:tableView];
	cell.dateFormatter = self.dateFormatter;
	cell.note = [self.notes objectAtIndex:indexPath.row];
	return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
	forRowAtIndexPath:(NSIndexPath *)indexPath
{
	//TODO: we need to block until we get the response so they can't click something else
	if (UITableViewCellEditingStyleDelete == editingStyle) {
		NSDictionary *note = [self.notes objectAtIndex:indexPath.row];
		__weak WelcomeViewController *bself = self;
		[RC2_SharedInstance() deleteNotification:[note objectForKey:@"id"] completionHandler:^(BOOL success, id results)
		{
			if (success) {
				[bself.notes removeObjectAtIndex:indexPath.row];
				[bself.noteTable deleteRowsAtIndexPaths:ARRAY(indexPath) withRowAnimation:UITableViewRowAnimationBottom];
			} else if (nil != results) {
				[UIAlertView showAlertWithTitle:@"Error Deleting Notification" message:results];
			}
		}];
	}
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 76;
}
@end
