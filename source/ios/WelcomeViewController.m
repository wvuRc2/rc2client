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
#import "ASIFormDataRequest.h"

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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesLoaded:) name:NotificationsReceivedNotification object:nil];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
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

#pragma mark - meat & potatos

-(void)pullToRefresh:(UIGestureRecognizer*)recog
{
	if (recog.state == UIGestureRecognizerStateRecognized) {
		[self reloadNotifications];
	}
}

-(void)reloadNotifications
{
	ASIHTTPRequest *theReq = [[Rc2Server sharedInstance] requestWithRelativeURL:@"notify"];
	__unsafe_unretained ASIHTTPRequest *req = theReq;
	__weak WelcomeViewController *blockSelf = self;
	[req setCompletionBlock:^{
		blockSelf.noteTable.refreshGestureRecognizer.refreshState = PHRefreshIdle;
		if (req.responseStatusCode == 200) {
			NSDictionary *d = [req.responseString JSONValue];
			if ([d objectForKey:@"status"] && [[d objectForKey:@"status"] intValue] == 0) {
				[blockSelf.notes removeAllObjects];
				[blockSelf.notes addObjectsFromArray:[d objectForKey:@"notes"]];
				[blockSelf.noteTable reloadData];
			}
		} else {
			Rc2LogWarn(@"error fetching notifications:%@", req.error);
		}
	}];
	[req startAsynchronous];
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
	if (UITableViewCellEditingStyleDelete == editingStyle) {
		NSDictionary *note = [self.notes objectAtIndex:indexPath.row];
		ASIHTTPRequest *req = [[Rc2Server sharedInstance] requestWithRelativeURL:[NSString stringWithFormat:@"notify/%@", [note objectForKey:@"id"]]];
		[req setRequestMethod:@"DELETE"];
		[req setTimeOutSeconds:3];
		[req startSynchronous];
		NSString *msg=nil;
		if (req.responseStatusCode == 200) {
			NSDictionary *d = [req.responseString JSONValue];
			if ([d objectForKey:@"status"] && [[d objectForKey:@"status"] intValue] == 0) {
				//worked
				[self.notes removeObjectAtIndex:indexPath.row];
				[self.noteTable deleteRowsAtIndexPaths:ARRAY(indexPath) withRowAnimation:UITableViewRowAnimationBottom];
			} else
				msg = [d objectForKey:@"message"];
		} else
			msg = @"Unknown server error";
		if (msg)
			[UIAlertView showAlertWithTitle:@"Error Deleting Notification" message:msg];
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
