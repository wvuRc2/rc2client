//
//  DropboxSyncSettingController.m
//  Rc2Client
//
//  Created by Mark Lilback on 6/20/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "DropboxSyncSettingController.h"
#import "RCWorkspace.h"
#import "Rc2Server.h"

@interface DropboxSyncSettingController ()
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, copy) NSArray *entries;
@end

@implementation DropboxSyncSettingController

-(id)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
	}
	return self;
}

-(void)viewDidLoad
{
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(userDone:)];
	self.navigationItem.rightBarButtonItem = doneButton;

	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"dbpath"];
	if (nil == self.thePath) {
		self.thePath = @"/";
		self.navigationItem.title = NSLocalizedString(@"Dropbox", @"");
	} else {
		self.navigationItem.title = self.thePath.lastPathComponent;
	}
	self.entries = [self.dropboxCache objectForKey:self.thePath];
	if (nil == self.entries) {
		self.restClient = [[DBRestClient alloc] initWithSession:(id)[DBSession sharedSession]];
		self.restClient.delegate = (id)self;
		[self.restClient loadMetadata:self.thePath];
	} else {
		[self.tableView reloadData];
	}
}

-(void)userDone:(id)sender
{
	self.workspace.dropboxPath = self.thePath;
	self.workspace.dropboxUser = [[[DBSession sharedSession] userIds] firstObject];
	[[Rc2Server sharedInstance] updateWorkspace:self.workspace completionBlock:^(BOOL success, id results) {
		if (!success)
			Rc2LogError(@"Failed to save db sync info:%@", results);
	}];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
	NSMutableArray *a = [NSMutableArray array];
	for (DBMetadata *item in metadata.contents) {
		if (item.isDirectory) {
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   @YES, @"isdir", item, @"metadata", nil]];
		}
	}
	self.entries = a;
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
	//need to push next item on the stack
	DropboxSyncSettingController *dfc = [[DropboxSyncSettingController alloc] init];
	dfc.workspace = self.workspace;
	dfc.thePath = [[item objectForKey:@"metadata"] path];
	dfc.dropboxCache = self.dropboxCache;
	[self.navigationController pushViewController:dfc animated:YES];
}

@end
