//
//  MCDropboxConfigWindow.m
//  Rc2Client
//
//  Created by Mark Lilback on 8/1/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import "MCDropboxConfigWindow.h"
#import "RCWorkspace.h"
#import "DropBlocks.h"

@interface DBItem : NSObject
+(NSArray*)itemsforMetadataArray:(NSArray*)inArray;
@property (nonatomic, strong, readonly) DBMetadata *metadata;
@property (nonatomic, copy, readonly) NSString *name;
@property (copy) NSArray *children;
@property (readonly) BOOL childrenLoaded;
@end

@interface MCDropboxConfigWindow () <NSBrowserDelegate>
@property (nonatomic, weak) IBOutlet NSBrowser *browser;
@property (nonatomic, weak) IBOutlet NSButton *saveButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *disableButton;
@property (nonatomic, strong) RCWorkspace *wspace;
@property (nonatomic, copy) NSArray *rootItems;
@end

@implementation MCDropboxConfigWindow
-(id)initWithWorkspace:(RCWorkspace*)wspace
{
	if ((self = [super initWithWindowNibName:@"MCDropboxConfigWindow"])) {
		self.wspace = wspace;
	}
	return self;
}

-(void)windowDidLoad
{
//	[self.browser setDefaultColumnWidth:220];
	_browser.maxVisibleColumns = 3;
//	_browser.minColumnWidth = 100;
//	for (NSInteger i=0; i <= _browser.lastColumn; i++)
//		[_browser setWidth:120 ofColumn:i];
	//load initial data
	[DropBlocks loadMetadata:@"/" completionBlock:^(DBMetadata *metadata, NSError *error) {
		self.rootItems = [DBItem itemsforMetadataArray:metadata.contents];
		[self.browser reloadColumn:0];
	}];
	[_browser setDoubleAction:@selector(saveChanges:)];
	[self updateUI];
}

-(IBAction)saveChanges:(id)sender
{
	DBItem *item = [_browser itemAtIndexPath:_browser.selectionIndexPath];
	NSLog(@"saving %@", item.metadata.path);
	self.handler(1);
}

-(IBAction)cancel:(id)sender
{
	self.handler(0);
}

-(IBAction)disableSync:(id)sender
{
	self.handler(-1);
}

-(void)updateUI
{
	DBItem *item = [_browser itemAtIndexPath:_browser.selectionIndexPath];
	[self.saveButton setEnabled:item != nil];
}

-(NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.rootItems.count;
	if (![item childrenLoaded]) {
		NSInteger col = browser.lastColumn;
		[DropBlocks loadMetadata:[[(DBItem*)item metadata] path] completionBlock:^(DBMetadata *metadata, NSError *error) {
			[item setChildren:[DBItem itemsforMetadataArray:metadata.contents]];
			[browser reloadColumn:col];
		}];
	}
	return [[item children] count];
}

-(id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
	if (nil == item)
		return [_rootItems objectAtIndex:index];
	return [[item children] objectAtIndex:index];
}

-(BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
	return ![item isDirectory];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
	return [item name];
}

-(void)browser:(NSBrowser *)browser didChangeLastColumn:(NSInteger)oldLastColumn toColumn:(NSInteger)column
{
	[self updateUI];
}

@end

@implementation DBItem

+(NSArray*)itemsforMetadataArray:(NSArray*)inArray
{
	NSMutableArray *out = [NSMutableArray arrayWithCapacity:inArray.count];
	for (DBMetadata *md in inArray) {
		if (md.isDirectory)
			[out addObject:[[DBItem alloc] initWithMetadata:md]];
	}
	return out;
}

-(id)initWithMetadata:(DBMetadata*)md
{
	if ((self = [super init])) {
		_metadata = md;
	}
	return self;
}

-(NSString*)name
{
	return _metadata.filename;
}

-(BOOL)isDirectory
{
	return _metadata.isDirectory;
}

-(BOOL)childrenLoaded
{
	return nil != _children;
}

@end
