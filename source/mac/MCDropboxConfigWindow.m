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
@property (assign) BOOL loadedChildren;
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
}

-(IBAction)saveChanges:(id)sender
{
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

-(NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
	if (nil == item)
		return self.rootItems.count;
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

@end

@implementation DBItem

+(NSArray*)itemsforMetadataArray:(NSArray*)inArray
{
	NSMutableArray *out = [NSMutableArray arrayWithCapacity:inArray.count];
	for (DBMetadata *md in inArray)
		[out addObject:[[DBItem alloc] initWithMetadata:md]];
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

@end
