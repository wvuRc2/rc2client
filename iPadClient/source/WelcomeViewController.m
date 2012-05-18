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
	// Do any additional setup after loading the view from its nib.
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

#pragma mark - meat & potatos

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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 76;
}

@synthesize noteTable=_noteTable;
@synthesize notes=_notes;
@synthesize dateFormatter=_dateFormatter;
@end
