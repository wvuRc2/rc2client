//
//  DropboxImportController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "DropboxImportController.h"
#import "DropboxImportCell.h"
#import "DropBlocks.h"
#import "Rc2Server.h"
#import "RCFile.h"
#import "RCWorkspace.h"
#import "RCSession.h"
#import "AMHudView.h"

NSString *const kLastDropBoxPathPref = @"LastDropBoxPath";

@interface DropboxImportController()
@property (nonatomic, strong) DBMetadata *metaData;
@property (nonatomic, copy) NSArray *entries;
@property (nonatomic, strong) NSMutableDictionary *currentDownload;
@property (nonatomic, strong) AMHudView *currentHud;
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
		self.currentHud = [AMHudView hudWithLabelText:@"Contacting Dropbox…"];
		//show hud on event loop
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.currentHud showOverView:self.view];
		});
		[DropBlocks loadMetadata:self.thePath completionBlock:^(DBMetadata *metadata, NSError *error) {
			[self.currentHud hide];
			if (metadata)
				[self metadataLoaded:metadata];
			else {
				//TODO: friendly error display
				Rc2LogError(@"dropbox import got md error:%@", error);
			}
		}];
	} else {
		[self.fileTable reloadData];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - meat & potatos

-(void)metadataLoaded:(DBMetadata*)metadata
{
	self.metaData = metadata;
	NSArray *fileTypes = [RC2_AcceptableImportFileSuffixes() arrayByPerformingSelector:@selector(lowercaseString)];
	NSMutableArray *a = [NSMutableArray array];
	for (DBMetadata *item in self.metaData.contents) {
		NSString *ftype = [[item.path pathExtension] lowercaseString];
		if (item.isDirectory) {
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   (id)kCFBooleanTrue, @"isdir", item, @"metadata", nil]];
		} else {
			NSNumber *importable = [NSNumber numberWithBool:([fileTypes containsObject:ftype]) && item.totalBytes > 0];
			[a addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:[item.path lastPathComponent], @"name",
						   @NO, @"isdir", item, @"metadata", importable, @"importable", nil]];
		}
	}
	self.entries = a;
	[self.dropboxCache setObject:a forKey:self.thePath];
	[self.fileTable reloadData];
}

-(void)downloadedAtPath:(NSString*)destPath
{
	RCWorkspace *wspace = self.session.workspace;
	self.currentHud = [AMHudView hudWithLabelText:@"Uploading to Rc²…"];
	[RC2_SharedInstance() importFile:[NSURL fileURLWithPath:destPath]
							   toContainer:wspace
						 completionHandler:^(BOOL ok, id results)
	 {
		 [self.currentHud hide];
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
	[self.currentHud showOverView:self.view];
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
		dfc.thePath = [item valueForKeyPath:@"metadata.path"];
		dfc.dropboxCache = self.dropboxCache;
		[self.navigationController pushViewController:dfc animated:YES];
	}
}

-(IBAction)importFile:(id)sender
{
	NSMutableDictionary *item = [self.entries objectAtIndex:[sender tag]];
	NSString *dbpath = [item valueForKeyPath:@"metadata.path"];
	//we need to decide were to temporarily save it
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[dbpath lastPathComponent]];
	if ([fm fileExistsAtPath:path]) {
		[fm removeItemAtPath:path error:nil];
		//FIXME: should do some error checking
	}
	self.currentDownload = item;
	self.currentHud = [AMHudView hudWithLabelText:@"Downloading File…"];
	//determinate progress only for larger files. otherwise, no progress is displayed
	if ([[item objectForKey:@"metadata"] totalBytes] > 4096)
		self.currentHud.progressDeterminate = YES;
	[self.currentHud showOverView:self.view];
	[DropBlocks loadFile:dbpath intoPath:path completionBlock:^(NSString *contentType, DBMetadata *metadata, NSError *error) {
		[self.currentHud hide];
		if (error) {
			self.currentDownload=nil;
			Rc2LogWarn(@"error loading file from dropbox:%@", error);
			[UIAlertView showAlertWithTitle:@"Error Loading File" message:error.localizedDescription];
		} else {
			[self downloadedAtPath:path];
		}
	} progressBlock:^(CGFloat pval) {
		if (self.currentHud.progressDeterminate)
			self.currentHud.progressValue = pval;
	}];
}

-(IBAction)userDone:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:self.thePath forKey:kLastDropBoxPathPref];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[(id)self.navigationController.delegate userDone:self.lastFileImported];
}

@end
