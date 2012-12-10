//
//  SessionFilesController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "SessionFilesController.h"
#import "Rc2Server.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "FileDetailsCell.h"

@interface SessionFilesController()
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
-(void)handleDoubleTap;
@end

@implementation SessionFilesController

- (id)init
{
	self = [super initWithNibName:@"SessionFilesController"	bundle:nil];
	return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	self.contentSizeForViewInPopover = CGSizeMake(320, 520);
	self.tableView.rowHeight = 52;
	__weak SessionFilesController *blockSelf = self;
	self.tableView.doubleTapHandler = ^(AMTableView *tv) {
		[blockSelf handleDoubleTap];
	};
	self.files = [[[Rc2Server sharedInstance] currentSession].workspace.files sortedArrayUsingComparator:^(RCFile *file1, RCFile *file2) {
		return [file1.name compare:file2.name];
	}];
	//add dropbox item to toolbar
	UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:@""]];
	button.momentary = YES;
	button.segmentedControlStyle = UISegmentedControlStyleBar;
	button.selectedSegmentIndex = UISegmentedControlNoSegment;
	[button setImage:[UIImage imageNamed:@"dropboxIcon"] forSegmentAtIndex:0];
	button.tintColor = [UIColor clearColor];
	[button addTarget:self action:@selector(doDropboxImport:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
	barButton.target = self;
	barButton.action = @selector(doDropboxImport:);
//	self.toolbar.tintColor = [UIColor clearColor];
	self.toolbar.items = [self.toolbar.items arrayByAddingObject:barButton];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:RCFileContainerChangedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

#pragma mark - actions

-(void)reloadData
{
	self.files = [[[Rc2Server sharedInstance] currentSession].workspace.files sortedArrayUsingComparator:^(RCFile *file1, RCFile *file2) {
		return [file1.name compare:file2.name];
	}];
	[self.tableView reloadData];
}

-(void)handleDoubleTap
{
	[self.delegate loadFile:[self.files objectAtIndex:[self.tableView indexPathForSelectedRow].row]];
}

-(IBAction)doNewFile:(id)sender
{
	[self.delegate dismissSessionsFilesController];
	[self.delegate doNewFile:sender];
}

-(IBAction)doDropboxImport:(id)sender
{
	[self.delegate dismissSessionsFilesController];
	[self.delegate presentDropboxImport:sender];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	FileDetailsCell *cell = [FileDetailsCell cellForTableView:tv];
	cell.dateFormatter = self.dateFormatter;
	RCFile *file = [self.files objectAtIndex:indexPath.row];
	[cell showValuesForFile:file];
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 75.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.delegate loadFile:[self.files objectAtIndex:indexPath.row]];
}

@end
