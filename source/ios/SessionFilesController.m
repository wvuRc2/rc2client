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
#import "RCProject.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "FileDetailsCell.h"

@interface SessionFilesController()
@property (nonatomic, weak) RCSession *session;
@property (nonatomic, copy) NSArray *fileSections;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
-(void)handleDoubleTap;
@end

@implementation SessionFilesController

- (id)initWithSession:(RCSession *)session
{
	self = [super initWithNibName:@"SessionFilesController"	bundle:nil];
	self.session = session;
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
	[self reloadData];
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
	NSArray *sortD = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
	NSMutableArray *srcFiles = [NSMutableArray array];
	NSMutableArray *sharedFiles = [NSMutableArray array];
	NSMutableArray *otherFiles = [NSMutableArray array];
	for (RCFile *aFile in self.session.workspace.files) {
		if (aFile.fileType.isSourceFile)
			[srcFiles addObject:aFile];
		else
			[otherFiles addObject:aFile];
	}
	[sharedFiles addObjectsFromArray:self.session.workspace.project.files];
	[srcFiles sortUsingDescriptors:sortD];
	[sharedFiles sortUsingDescriptors:sortD];
	[otherFiles sortUsingDescriptors:sortD];
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:3];
	if (srcFiles.count > 0)
		[a addObject:@{@"name":@"Source Files", @"files":srcFiles}];
	if (sharedFiles.count > 0)
		[a addObject:@{@"name":@"Shared Files", @"files":sharedFiles}];
	if (otherFiles.count > 0)
		[a addObject:@{@"name":@"Other Files", @"files":otherFiles}];
	self.fileSections = a;

	[self.tableView reloadData];
}

-(void)handleDoubleTap
{
	NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
	[self.delegate loadFile:[self fileAtIndexPath:ipath]];
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

#pragma mark - meat & potato

-(RCFile*)fileAtIndexPath:(NSIndexPath*)indexPath
{
	NSDictionary *sectDict = [self.fileSections objectAtIndex:indexPath.section];
	return [[sectDict objectForKey:@"files"] objectAtIndex:indexPath.row];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.fileSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSDictionary *sectDict = [self.fileSections objectAtIndex:section];
	return [[sectDict objectForKey:@"files"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCFile *file = [self fileAtIndexPath:indexPath];
	FileDetailsCell *cell = [FileDetailsCell cellForTableView:tv];
	cell.dateFormatter = self.dateFormatter;
	[cell showValuesForFile:file];
	
	return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self.fileSections objectAtIndex:section] objectForKey:@"name"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 75.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.delegate loadFile:[self fileAtIndexPath:indexPath]];
}

@end
