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
#import "RCSessionUser.h"
#import "RCWorkspace.h"
#import "RCProject.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "FileDetailsCell.h"
#import "Rc2AppConstants.h"

@interface SessionFilesController() <UISearchBarDelegate>
@property (nonatomic, weak) RCSession *session;
@property (nonatomic, copy) NSArray *fileSections;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *syncButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, copy) NSArray *searchResults;
@property (nonatomic) BOOL inSearchMode;
-(void)handleDoubleTap;
@end

@implementation SessionFilesController

- (id)initWithSession:(RCSession *)session
{
	self = [super initWithNibName:@"SessionFilesController"	bundle:nil];
	self.session = session;
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	self.preferredContentSize = CGSizeMake(320, 520);
	self.tableView.rowHeight = 52;
	[self.tableView registerNib:[UINib nibWithNibName:@"FileDetailsCell" bundle:nil] forCellReuseIdentifier:@"file"];
	[self.tableView registerNib:[UINib nibWithNibName:@"FileSearchResultCell" bundle:nil] forCellReuseIdentifier:@"search"];
	__weak SessionFilesController *blockSelf = self;
	self.tableView.doubleTapHandler = ^(AMTableView *tv) {
		[blockSelf handleDoubleTap];
	};
	[self reloadData];
	//add dropbox item to toolbar
	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dropboxIcon"] style:UIBarButtonItemStyleBordered target:self action:@selector(doDropboxImport:)];
	if (barButton) {
		barButton.target = self;
		barButton.action = @selector(doDropboxImport:);
		NSMutableArray *titems = [self.toolbar.items mutableCopy];
		[titems insertObject:barButton atIndex:0];
		self.toolbar.items = titems;
	} else {
		Rc2LogWarn(@"failed to init dropbox button");
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:RCFileContainerChangedNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

#pragma mark - actions

-(IBAction)toggleSearch:(id)sender
{
	CGRect closedFrame = CGRectMake(0, 0, self.view.frame.size.width, 0);
	CGRect openFrame = CGRectMake(0, 0, self.view.frame.size.width, 44);
	if (nil == self.searchBar) {
		self.searchBar = [[UISearchBar alloc] initWithFrame:closedFrame];
		self.searchBar.delegate = self;
		self.tableView.tableHeaderView = self.searchBar;
	}
	BOOL visible = self.searchBar.frame.size.height > 0;
	CGRect newFrame = visible ? closedFrame : openFrame;
	@synchronized(self) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3f];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		if (visible)
			[self.searchBar resignFirstResponder];
		[self.tableView beginUpdates];

		self.searchBar.frame = newFrame;
		self.tableView.tableHeaderView = self.searchBar;

		[self.tableView endUpdates];
		[UIView commitAnimations];
		self.inSearchMode = !visible; //we changed the value of visible
		[self.tableView reloadData];
		if (self.inSearchMode)
			[self.searchBar becomeFirstResponder];
	}
}

-(IBAction)doDBSync:(id)sender
{
	[self.delegate dismissSessionsFilesController];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDropboxSyncRequestedNotification object:self.session.workspace];
}


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
	[a addObject:@{@"name":@"Source Files", @"files":srcFiles}];
	[a addObject:@{@"name":@"Shared Files", @"files":sharedFiles}];
	if (otherFiles.count > 0)
		[a addObject:@{@"name":@"Other Files", @"files":otherFiles}];
	self.fileSections = a;

	[self.tableView reloadData];
}

-(void)handleDoubleTap
{
	NSIndexPath *ipath = [self.tableView indexPathForSelectedRow];
	[self.delegate loadFile:[self fileAtIndexPath:ipath] fromSearch:nil];
}

-(IBAction)doNewFile:(id)sender
{
	[self.delegate dismissSessionsFilesController];
	[self.delegate doNewFile:sender];
}

-(IBAction)doNewSharedFile:(id)sender
{
	[self.delegate dismissSessionsFilesController];
	[self.delegate doNewSharedFile:sender];
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

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if (searchText.length < 1) {
		self.searchResults = nil;
		return;
	}
	[self.session searchFiles:searchText handler:^(NSArray *matches) {
		@synchronized(self) {
			self.searchResults = matches;
			[self.tableView reloadData];
		}
	}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.inSearchMode)
		return 1;
	return self.fileSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.inSearchMode)
		return self.searchResults.count;
	NSDictionary *sectDict = [self.fileSections objectAtIndex:section];
	return [[sectDict objectForKey:@"files"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	FileDetailsCell *cell;
	if (self.inSearchMode) {
		NSDictionary *fileDict = [self.searchResults objectAtIndex:indexPath.row];
		cell = [tv dequeueReusableCellWithIdentifier:@"search"];
		[cell showValuesForFile:fileDict[@"file"] snippet:fileDict[@"snippet"]];
	} else {
		RCFile *file = [self fileAtIndexPath:indexPath];
		cell = [tv dequeueReusableCellWithIdentifier:@"file"];
		cell.dateFormatter = self.dateFormatter;
		[cell showValuesForFile:file];
	}
	return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.inSearchMode)
		return NO;
	return self.session.hasWritePerm;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.delegate dismissSessionsFilesController];
		[self.delegate doDeleteFile:[self fileAtIndexPath:indexPath]];
	}
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (self.inSearchMode)
		return @"Search Results";
	return [[self.fileSections objectAtIndex:section] objectForKey:@"name"];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	if (section > 1 || self.inSearchMode)
		return;
	UITableViewHeaderFooterView *hfview = (id)view;
	CGRect frame = hfview.contentView.frame;
	frame.origin.x = CGRectGetMaxX(frame) - 34;
	frame.size.width = frame.size.height;
	frame = CGRectInset(frame, 4, 6);
	
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.frame = frame;
	[btn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
	[btn setImage:[UIImage imageNamed:@"addDown"] forState:UIControlStateHighlighted];
	[hfview.contentView addSubview:btn];
	if (section == 1)
		[btn addTarget:self action:@selector(doNewSharedFile:) forControlEvents:UIControlEventTouchUpInside];
	else
		[btn addTarget:self action:@selector(doNewFile:) forControlEvents:UIControlEventTouchUpInside];
	
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	RCFile *file = self.inSearchMode ? self.searchResults[indexPath.row][@"file"] : [self fileAtIndexPath:indexPath];
	NSString *searchStr = self.inSearchMode ? self.searchBar.text : nil;
	[self.delegate loadFile:file fromSearch:searchStr];
}

@end
