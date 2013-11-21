//
//  DropboxFolderSelectController.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/20/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "DropboxFolderSelectController.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"

@interface DropboxFolderSelectController ()
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, copy) NSArray *entries;
@property (nonatomic, copy) NSArray *fileEntries;
@end

@implementation DropboxFolderSelectController

-(id)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
	}
	return self;
}

-(void)viewDidLoad
{
	UIBarButtonItem *doneButton;
	if (self.doneButtonTitle)
		doneButton = [[UIBarButtonItem alloc] initWithTitle:self.doneButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(userDone:)];
	else
		doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(userDone:)];
	self.navigationItem.rightBarButtonItem = doneButton;

	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"dbpath"];
	if (nil == self.thePath) {
		self.thePath = @"/";
		if (nil == self.navigationItem.title)
			self.navigationItem.title = NSLocalizedString(@"Dropbox", @"");
	} else {
		self.navigationItem.title = self.thePath.lastPathComponent;
	}
	[self loadEntries:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (self.navigationController.viewControllers.firstObject == self) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userCanceled:)];
	}
}

-(void)loadEntries:(BOOL)force
{
	self.entries = [self.dropboxCache objectForKey:self.thePath];
	if (force)
		self.entries = nil;
	if (nil == self.entries) {
		self.restClient = [[DBRestClient alloc] initWithSession:(id)[DBSession sharedSession]];
		self.restClient.delegate = (id)self;
		[self.restClient loadMetadata:self.thePath];
	} else {
		[self.tableView reloadData];
	}
}

-(void)userCanceled:(id)sender
{
	if (self.modalInPopover)
		[self.navigationController popToRootViewControllerAnimated:YES];
	if (self.doneHandler)
		self.doneHandler(self, nil);
}

-(void)userDone:(id)sender
{
	if (self.modalInPopover)
		[self.navigationController popToRootViewControllerAnimated:YES];
	if (self.doneHandler)
		self.doneHandler(self, self.thePath);
}

-(NSString*)revisiionIdForFile:(NSString*)fileName
{
	return [[self.fileEntries firstObjectWithValue:fileName forKey:@"filename"] rev];
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
	NSMutableArray *a = [NSMutableArray array];
	NSMutableArray *fe = [NSMutableArray array];
	for (DBMetadata *item in metadata.contents) {
		if (item.isDirectory) {
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   @YES, @"isdir", item, @"metadata", nil]];
		} else {
			[fe addObject:item];
		}
	}
	self.entries = a;
	self.fileEntries = fe;
	[self.dropboxCache setObject:a forKey:self.thePath];
	[self.tableView reloadData];
}

-(void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
	//likely a 404. we'll pop to our parent
	[self.navigationController popViewControllerAnimated:NO];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.entries.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dbpath"];
	NSDictionary *item = [self.entries objectAtIndex:indexPath.row];
	cell.textLabel.text = item[@"name"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *item = [self.entries objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:[self prepareChildControllerForPath:[[item objectForKey:@"metadata"] path]] animated:YES];
}

-(DropboxFolderSelectController*)prepareChildControllerForPath:(NSString*)path
{
	//need to push next item on the stack
	DropboxFolderSelectController *dfc = [[DropboxFolderSelectController alloc] init];
	dfc.workspace = self.workspace;
	dfc.doneHandler = self.doneHandler;
	dfc.doneButtonTitle = self.doneButtonTitle;
	dfc.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	dfc.navigationItem.rightBarButtonItems = [self.navigationItem.rightBarButtonItems copy];
	dfc.thePath = path;
	dfc.dropboxCache = self.dropboxCache;
	return dfc;
}

-(NSString*)description
{
	return [[super description] stringByAppendingFormat:@" %@", self.thePath];
}

@end
