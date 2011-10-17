//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacSessionViewController.h"
#import "MCWebOutputController.h"
#import "Rc2Server.h"
#import "RCMacToolbarItem.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCMTextView.h"
#import <Vyana/AMWindow.h>

@interface MacSessionViewController() {
	CGFloat __fileListWidth;
	BOOL __didInit;
	BOOL __movingFileList;
}
@property (nonatomic, strong) NSMenu *addMenu;
@property (nonatomic, strong) MCWebOutputController *outputController;
@property (nonatomic, strong) RCFile *selectedFile;
@property (nonatomic, copy) NSString *scratchString;
-(void)prepareForSession;
-(void)completeSessionStartup:(id)response;
@end

@implementation MacSessionViewController
@synthesize session=__session;
@synthesize selectedFile=__selFile;

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		self.session = aSession;
		self.session.delegate = self;
		self.scratchString=@"";
	}
	return self;
}

-(void)dealloc
{
	self.contentSplitView.delegate=nil;
	self.selectedFile=nil;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didInit) {
		self.outputController = [[MCWebOutputController alloc] init];
		NSView *croot = [self.contentSplitView.subviews objectAtIndex:1];
		[croot addSubview:self.outputController.view];
		self.outputController.view.frame = croot.bounds;
		self.busy = YES;
		self.statusMessage = @"Connecting to server…";
		[self prepareForSession];
		self.addMenu = [[NSMenu alloc] initWithTitle:@""];
		//read this instead of hard-coding a value that chould change in the nib
		__fileListWidth = self.contentSplitView.frame.origin.x;

		__didInit=YES;
	}
}

-(void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	NSToolbar *tbar = [NSApp valueForKeyPath:@"delegate.mainWindowController.window.toolbar"];
	RCMacToolbarItem *ti = [tbar.items firstObjectWithValue:@"add" forKey:@"itemIdentifier"];
	if (newSuperview) {
		[ti pushActionMenu:self.addMenu];
	} else {
		[ti popActionMenu:self.addMenu];
	}
}

-(void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if ([newWindow isKindOfClass:[AMWindow class]] && 
		[[newWindow valueForKey:@"windowController"] class] == NSClassFromString(@"RCMSessionWindowController"))
	{
		if (self.fileContainerView.frame.origin.x < 0)
			[self toggleFileList:nil];
	} else {
		if (self.fileContainerView.frame.origin.x >= 0)
			[self toggleFileList:nil];
	}
}

-(void)viewDidMoveToWindow
{
	[self.view.window makeFirstResponder:self.editView];
}

#pragma mark - actions

-(IBAction)toggleFileList:(id)sender
{
	__movingFileList=YES;
	NSRect fileRect = self.fileContainerView.frame;
	NSRect contentRect = self.contentSplitView.frame;
	CGFloat offset = __fileListWidth;
	if (self.fileContainerView.frame.origin.x < 0) {
		fileRect.origin.x += offset;
		contentRect.origin.x += offset;
		contentRect.size.width -= offset;
	} else {
		fileRect.origin.x -= offset;
		contentRect.origin.x -= offset;
		contentRect.size.width += offset;
	}
	if (self.view.window) {
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			[self.fileContainerView.animator setFrame:fileRect];
			[self.contentSplitView.animator setFrame:contentRect];
		} completionHandler:^{
			__movingFileList=NO;
		}];
	} else {
		[self.fileContainerView setFrame:fileRect];
		[self.contentSplitView setFrame:contentRect];
		__movingFileList=NO;
	}
}

-(IBAction)executeScript:(id)sender
{
	
}

-(IBAction)makeBusy:(id)sender
{
	self.busy = ! self.busy;
	self.statusMessage = @"hoo boy";
}

#pragma mark - meat & potatos

-(void)saveChanges
{
	self.selectedFile=nil;
}

-(void)completeSessionStartup:(id)response
{
	[self.session updateWithServerResponse:response];
	[self.session startWebSocket];
}

-(void)prepareForSession
{
	[[Rc2Server sharedInstance] prepareWorkspace:self.session.workspace completionHandler:^(BOOL success, id response) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self completeSessionStartup:response];
			});
		} else {
			//TODO: better error handling
			self.statusMessage = [NSString stringWithFormat:@"Error preparing workspace: (%@)", response];
		}
	}];
}

#pragma mark - session delegate

-(void)connectionOpened
{
	self.busy=NO;
	self.statusMessage = @"Connected";
}

-(void)connectionClosed
{
	self.statusMessage = @"Disconnected";
}

-(void)handleWebSocketError:(NSError*)error
{
	[self presentError:error];
}

-(void)processWebSocketMessage:(NSDictionary*)msg json:(NSString*)jsonString
{
	
}

-(void)performConsoleAction:(NSString*)action
{
	
}

-(void)displayImage:(NSString*)imgPath
{
	
}

#pragma mark - text view delegate

-(BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if (commandSelector == @selector(insertNewline:)) {
		if ([NSApp currentEvent].keyCode == 76) {
			//enter key
			[self.executeButton performClick:self];
			return YES;
		}
	}
	return NO;
}

#pragma mark - table view

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	RCFile *file = [self.session.workspace.files objectAtIndexNoExceptions:[self.fileTableView selectedRow]];
	self.selectedFile = file;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.session.workspace.files.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn 
	row:(NSInteger)row
{
	RCFile *file = [self.session.workspace.files objectAtIndexNoExceptions:row];
	return file.name;
}

#pragma mark - split view

-(CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition 
		ofSubviewAt:(NSInteger)dividerIndex
{
	return 100;
}

-(void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if (!__movingFileList) {
		[splitView adjustSubviews];
	} else {
		NSView *leftView = [splitView.subviews objectAtIndex:0];
		NSView *rightView = [splitView.subviews objectAtIndex:1];
		NSRect leftViewFrame = leftView.frame;
		NSRect rightViewFrame = rightView.frame;
		CGFloat offset = splitView.frame.size.width - oldSize.width;
		leftViewFrame.size.width += offset;
		rightViewFrame.origin.x += offset;
		leftView.frame = leftViewFrame;
		rightView.frame = rightViewFrame;
	} 
}

#pragma mark - accessors/synthesizers

-(void)setSession:(RCSession *)session
{
	if (__session == session)
		return;
	if (__session) {
		[__session closeWebSocket];
		__session.delegate=nil;
	}
	__session = session;
}

-(void)setSelectedFile:(RCFile *)selectedFile
{
	if (__selFile) {
		if ([__selFile.fileContents isEqualToString:self.editView.string])
			[__selFile setLocalEdits:@""];
		else
			[__selFile setLocalEdits:self.editView.string];
	} else
		self.scratchString = self.editView.string;
	__selFile = selectedFile;
	NSString *newTxt = self.scratchString;
	if (selectedFile)
		newTxt = selectedFile.currentContents;
	NSMutableString *mstr = self.editView.textStorage.mutableString;
	[mstr replaceCharactersInRange:NSMakeRange(0, mstr.length) withString:newTxt];
}

@synthesize contentSplitView;
@synthesize fileTableView;
@synthesize outputController;
@synthesize addMenu;
@synthesize fileContainerView;
@synthesize editView;
@synthesize executeButton;
@synthesize scratchString;
@end

@implementation SessionView
@end