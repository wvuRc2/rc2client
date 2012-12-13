//
//  DropboxImportController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "DropboxImportController.h"
#import "DropboxImportCell.h"
#import "MBProgressHUD.h"
#import "Rc2Server.h"
#import "RCFile.h"
#import "RCWorkspace.h"
#import "RCSession.h"

@interface DropboxImportController()
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) DBMetadata *metaData;
@property (nonatomic, copy) NSArray *entries;
@property (nonatomic, strong) NSMutableDictionary *currentDownload;
@property (nonatomic, strong) MBProgressHUD *currentProgress;
@property (nonatomic, strong) RCFile *lastFileImported;
-(IBAction)userDone:(id)sender;
-(IBAction)importFile:(id)sender;
@end

@implementation DropboxImportController

- (id)init
{
	self = [super initWithNibName:@"DropboxImportController" bundle:nil];
	if (self) {
		// Custom initialization
	}
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					target:self
																				action:@selector(userDone:)];
	self.navigationItem.rightBarButtonItem = doneButton;

	if (nil == self.thePath) {
		self.thePath = @"/";
		self.navigationItem.title = NSLocalizedString(@"Dropbox", @"");
	} else {
		self.navigationItem.title = [self.thePath lastPathComponent];
	}
	//load our data
	self.entries = [self.dropboxCache objectForKey:self.thePath];
	if (nil == self.entries) {
		self.restClient = [[DBRestClient alloc] initWithSession:(id)[DBSession sharedSession]];
		self.restClient.delegate = (id)self;
		[self.restClient loadMetadata:self.thePath];
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		hud.labelText = @"Contacting Dropbox…";
	} else {
		[self.fileTable reloadData];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DropboxImportCell *cell = [DropboxImportCell cellForTableView:tv];
	NSDictionary *item = [self.entries objectAtIndex:indexPath.row];
	cell.textLabel.text = [item objectForKey:@"name"];
	if ([[item objectForKey:@"isdir"] boolValue])
		[cell treatAsDirectory];
	else if ([[item objectForKey:@"imported"] boolValue])
		[cell treatAsImported];
	else if ([[item objectForKey:@"importable"] boolValue]) {
		[cell treatAsImportable];
		[cell.importButton addTarget: self action:@selector(importFile:) forControlEvents:UIControlEventTouchUpInside];
		cell.importButton.tag = indexPath.row;
	} else
		[cell treatAsUnsupported];
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *item = [self.entries objectAtIndex:indexPath.row];
	if ([[item objectForKey:@"isdir"] boolValue])
		return indexPath;
	return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *item = [self.entries objectAtIndex:indexPath.row];
	if ([[item objectForKey:@"isdir"] boolValue]) {
		//need to push next item on the stack
		DropboxImportController *dfc = [[DropboxImportController alloc] init];
		dfc.session = self.session;
		dfc.thePath = [[item objectForKey:@"metadata"] path];
		dfc.dropboxCache = self.dropboxCache;
		[self.navigationController pushViewController:dfc animated:YES];
	}
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
	self.metaData = metadata;
	NSArray *fileTypes = [Rc2Server acceptableImportFileSuffixes];
	NSMutableArray *a = [NSMutableArray array];
	for (DBMetadata *item in self.metaData.contents) {
		NSString *ftype = [item.path pathExtension];
		if (item.isDirectory) {
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   (id)kCFBooleanTrue, @"isdir", item, @"metadata", nil]];
		} else {
			NSNumber *importable = [NSNumber numberWithBool:([fileTypes containsObject:ftype]) && item.totalBytes > 0];
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   (id)kCFBooleanFalse, @"isdir", item, @"metadata", importable, @"importable", nil]];
		}
	}
	self.entries = a;
	[self.dropboxCache setObject:a forKey:self.thePath];
	[self.fileTable reloadData];
	[MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
	RCWorkspace *wspace = self.session.workspace;
	self.currentProgress.mode = MBProgressHUDModeIndeterminate;
	self.currentProgress.labelText = @"Uploading to Rc²…";
	[[Rc2Server sharedInstance] importFile:[NSURL fileURLWithPath:destPath] 
								 toContainer:wspace
						 completionHandler:^(BOOL ok, id results)
	{
		[MBProgressHUD hideHUDForView:self.view animated:YES];
		self.currentProgress=nil;
		if (ok) {
			[self.currentDownload setObject:@YES forKey:@"imported"];
			[wspace addFile:results];
			[self.fileTable reloadData];
			self.lastFileImported = results;
			[[NSFileManager defaultManager] moveItemAtPath:destPath toPath:[results fileContentsPath] error:nil];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Error"
															message:results
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		self.currentDownload=nil;
	}];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
	self.currentProgress.progress = progress;
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	self.currentDownload=nil;
	self.currentProgress=nil;
	//FIXME: display error message
}

-(IBAction)importFile:(id)sender
{
	NSMutableDictionary *item = [self.entries objectAtIndex:[sender tag]];
	NSString *dbpath = [[item objectForKey:@"metadata"] path];
	//we need to decide were to temporarily save it
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[dbpath lastPathComponent]];
	if ([fm fileExistsAtPath:path]) {
		[fm removeItemAtPath:path error:nil];
		//FIXME: should do some error checking
	}
	self.currentDownload = item;
	self.currentProgress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	//determinate progress only for larger files. otherwise, no progress is displayed
	if ([[item objectForKey:@"metadata"] totalBytes] > 8192)
		self.currentProgress.mode = MBProgressHUDModeDeterminate;
	self.currentProgress.labelText = @"Downloading file…";
	[self.restClient loadFile:dbpath intoPath:path];
	
}

-(IBAction)userDone:(id)sender
{
	[(id)self.navigationController.delegate userDone:self.lastFileImported];
}

-(void)setSession:(RCSession *)session
{
	if (nil == session)
		NSLog(@"setting session to nil");
	__session = session;
	NSLog(@"setting session %@", __session);
}

@synthesize session=__session;
@end
