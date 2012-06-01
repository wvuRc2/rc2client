//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MacSessionViewController.h"
#import "MCWebOutputController.h"
#import "RCMImageViewer.h"
#import "RCMMultiImageController.h"
#import "RCMPDFViewController.h"
#import "RCMTextPrintView.h"
#import "Rc2Server.h"
#import "RCMacToolbarItem.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCImage.h"
#import "RCSessionUser.h"
#import "RCSavedSession.h"
#import "RCMTextView.h"
#import "MCNewFileController.h"
#import "RCMAppConstants.h"
#import <Vyana/AMWindow.h>
#import "ASIHTTPRequest.h"
#import "AppDelegate.h"
#import "RCMSessionFileCellView.h"
#import "MultiFileImporter.h"
#import "RCMSyntaxHighlighter.h"
#import "RCAudioChatEngine.h"
#import "RCImageCache.h"
#import "NoodleLineNumberView.h"

@interface MacSessionViewController() {
	CGFloat __fileListWidth;
	NSPoint __curImgPoint;
	BOOL __didInit;
	BOOL __movingFileList;
	BOOL __fileListInitiallyVisible;
	BOOL __didFirstLoad;
	BOOL __didFirstWindow;
	BOOL __toggledFileViewOnFullScreen;
}
@property (nonatomic, strong) IBOutlet NSButton *backButton;
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
//@property (nonatomic, strong) NSOperationQueue *dloadQueue;
@property (nonatomic, strong) NSMenu *addMenu;
@property (nonatomic, strong) MCWebOutputController *outputController;
@property (nonatomic, strong) RCFile *selectedFile;
@property (nonatomic, copy) NSString *scratchString;
@property (nonatomic, strong) NSPopover *imagePopover;
@property (nonatomic, strong) RCMImageViewer *imageController;
@property (nonatomic, strong) NSArray *currentImageGroup;
@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSNumber *fileIdJustImported;
@property (nonatomic, strong) id fullscreenToken;
@property (nonatomic, strong) id usersToken;
@property (nonatomic, strong) id modeChangeToken;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) NSString *webTmpFileDirectory;
-(void)prepareForSession;
-(void)completeSessionStartup:(id)response;
-(NSString*)escapeForJS:(NSString*)str;
-(void)handleFileImport:(NSURL*)fileUrl;
-(void)handleNewFile:(NSString*)fileName;
-(BOOL)fileListVisible;
-(void)syncFile:(RCFile*)file;
-(void)setMode:(NSString*)mode;
-(void)modeChanged;
@end

@implementation MacSessionViewController
@synthesize session=__session;
@synthesize selectedFile=__selFile;
@synthesize restrictedMode=_restrictedMode;

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		NSError *err=nil;
		self.session = aSession;
		self.session.delegate = self;
		self.scratchString=@"";
		self.users = [NSArray array];
		for (RCFile *file in self.session.workspace.files)
			[file updateContentsFromServer];
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
		__unsafe_unretained MacSessionViewController *blockSelf = self;
		self.modeChangeToken = [aSession addObserverForKeyPath:@"mode" task:^(id obj, NSDictionary *change) {
			[blockSelf modeChanged];
		}];
	}
	return self;
}

-(void)dealloc
{
//	[self.outputController.webView unbind:@"enabled"];
	self.contentSplitView.delegate=nil;
	[self unregisterAllNotificationTokens];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didInit) {
		self.outputController = [[MCWebOutputController alloc] init];
		NSView *croot = [self.contentSplitView.subviews objectAtIndex:1];
		[croot addSubview:self.outputController.view];
		self.outputController.view.frame = croot.bounds;
		self.outputController.delegate = (id)self;
		if (!self.session.socketOpen) {
			self.busy = YES;
			self.statusMessage = @"Connecting to server…";
			[self prepareForSession];
		}
//		[self.outputController.webView bind:@"enabled" toObject:self withKeyPath:@"restricted" options:nil];
		self.addMenu = [[NSMenu alloc] initWithTitle:@"Add a File"];
		[self.addMenu setAutoenablesItems:NO];
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"New File…" action:@selector(createNewFile:) keyEquivalent:@""];
		mi.target = self;
		[mi setEnabled:YES];
		[self.addMenu addItem:mi];
		mi = [[NSMenuItem alloc] initWithTitle:@"Import File…" action:@selector(importFile:) keyEquivalent:@""];
		mi.target = self;
		[self.addMenu addItem:mi];
		//read this instead of hard-coding a value that chould change in the nib
		__fileListWidth = self.contentSplitView.frame.origin.x;
		self.audioEngine = [[RCAudioChatEngine alloc] init];
		self.audioEngine.session = self.session;

		NSImage *timg = [NSImage imageNamed:NSImageNameGoLeftTemplate];
		[timg setSize:NSMakeSize(16, 16)];
		NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
		[img lockFocus];
		[timg drawInRect:NSMakeRect(8, 8, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[img unlockFocus];
		[img setTemplate:YES];
		self.backButton.image = img;
		
		//line numbers
		NoodleLineNumberView *lnv = [[NoodleLineNumberView alloc] initWithScrollView:self.editView.enclosingScrollView];
		[self.editView.enclosingScrollView setVerticalRulerView:lnv];
		[self.editView.enclosingScrollView setRulersVisible:YES];
		
		//caches
		__unsafe_unretained MacSessionViewController *blockSelf = self;
		[self storeNotificationToken:[[NSNotificationCenter defaultCenter] addObserverForName:RCWorkspaceFilesFetchedNotification 
														  object:nil queue:nil usingBlock:^(NSNotification *note)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[blockSelf.fileTableView reloadData];
				if (blockSelf.fileIdJustImported) {
					NSUInteger idx = [blockSelf.session.workspace.files indexOfObjectWithValue:blockSelf.fileIdJustImported usingSelector:@selector(fileId)];
					if (NSNotFound != idx) {
						[blockSelf.fileTableView amSelectRow:idx byExtendingSelection:NO];
					}
					blockSelf.fileIdJustImported=nil;
					[blockSelf tableViewSelectionDidChange:nil];
				}
			});
		}]];
		self.fullscreenToken = [[NSApp delegate] addObserverForKeyPath:@"isFullScreen" task:^(id obj, NSDictionary *change)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				if ([obj isFullScreen]) {
					if (!blockSelf.fileListVisible) {
						[blockSelf toggleFileList:blockSelf];
						blockSelf->__toggledFileViewOnFullScreen = YES;
					}
				} else if (blockSelf->__toggledFileViewOnFullScreen && blockSelf.fileListVisible) {
					[blockSelf toggleFileList:blockSelf];
					blockSelf->__toggledFileViewOnFullScreen = NO;
				}
			});
		}];
		self.usersToken = [self.session addObserverForKeyPath:@"users" task:^(id obj, NSDictionary *change)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				blockSelf.users = blockSelf.session.users;
				[blockSelf.userTableView reloadData];
			});
		}];
		[self.fileTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
		[self.fileTableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleNone];
		[self.fileTableView registerForDraggedTypes:ARRAY((id)kUTTypeFileURL)];
		[self.modeLabel setHidden:YES];
		__didInit=YES;
	}
}

-(void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	NSToolbar *tbar = [NSApp valueForKeyPath:@"delegate.mainWindowController.window.toolbar"];
	RCMacToolbarItem *ti = [tbar.items firstObjectWithValue:RCMToolbarItem_Add forKey:@"itemIdentifier"];
	if (!__didFirstLoad) {
		if (newSuperview) {
			RCSavedSession *savedState = self.session.savedSessionState;
			[self restoreSessionState:savedState];
			[ti pushActionMenu:self.addMenu];
		}
		__didFirstLoad=YES;
	} else if (newSuperview == nil) {
		[self saveSessionState];
		[self.audioEngine tearDownAudio];
		[ti popActionMenu:self.addMenu];
		if (self.webTmpFileDirectory) {
			[[NSFileManager defaultManager] removeItemAtPath:self.webTmpFileDirectory error:nil];
			self.webTmpFileDirectory=nil;
		}
	}
	if (newSuperview != nil) {
		if (self.session.initialFileSelection) {
			self.selectedFile = self.session.initialFileSelection;
			self.session.initialFileSelection = nil;
		}
	}
}

-(void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (!__didFirstWindow) {
		if (self.fileListVisible != __fileListInitiallyVisible)
			[self toggleFileList:nil];
		__didFirstWindow=YES;
	}
}

-(void)viewDidMoveToWindow
{
	[self.view.window makeFirstResponder:self.editView];
}

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(toggleFileList:)) {
		if ([(id)item isKindOfClass:[NSMenuItem class]]) {
			//adjust the title
			[(NSMenuItem*)item setTitle:self.fileListVisible ? @"Hide File List" : @"Show File List"];
		}
		return YES;
	} else if (action == @selector(exportFile:)) {
		return self.selectedFile != nil;
	} else if (action == @selector(importFile:) || action == @selector(createNewFile:)) {
		return self.session.hasWritePerm;
	} else if (action == @selector(saveFileEdits:)) {
		return self.selectedFile.isTextFile && ![self.editView.string isEqualToString:self.selectedFile.currentContents];
	} else if (action == @selector(toggleUsers:)) {
		return YES;
	} else if (action == @selector(changeMode:)) {
		return self.session.currentUser.master;
	} else if (action == @selector(contextualHelp:)) 
		return YES;
	return NO;
}

-(BOOL)fileListVisible
{
	return self.fileContainerView.frame.origin.x >= 0;
}

#pragma mark - actions

-(IBAction)changeMode:(id)sender
{
	NSString *mode = kMode_Share;
	switch (self.modePopUp.indexOfSelectedItem) {
		case 1:
			mode = kMode_Control;
			break;
		case 2:
			mode = kMode_Classroom;
			break;
	}
	[self.session requestModeChange:mode];
}

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
	//is the current file R or Rnw?
	if ([self.selectedFile.name hasSuffix:@".Rnw"]) {
		[self.session executeSweave:self.selectedFile.name script:self.editView.string];
	} else if ([self.selectedFile.name hasSuffix:@".sas"]) {
		[self.session executeSas:self.selectedFile];
	} else {
		[self.session executeScript:self.editView.string scriptName:self.selectedFile.name];
	}
}

-(IBAction)exportFile:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:self.selectedFile.name];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		NSError *err=nil;
		if (self.selectedFile.isTextFile) {
			[self.selectedFile.currentContents writeToURL:savePanel.URL atomically:YES encoding:NSUTF8StringEncoding error:&err];
		} else {
			[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:self.selectedFile.fileContentsPath] 
													toURL:savePanel.URL 
													error:&err];
		}
		if (err) {
			//FIXME: report error to user
			Rc2LogWarn(@"error exporting file:%@", err);
		}
	}];
}

-(IBAction)importFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:[Rc2Server acceptableImportFileSuffixes]];
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (NSFileHandlingPanelCancelButton == result)
			return;
		[self handleFileImport:[[openPanel URLs] firstObject]];
	}];
}

-(IBAction)deleteFile:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Delete File?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Are you sure you want to delete the file \"%@\"? This action can not be undone.", self.selectedFile.name];
	[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *theAlert, NSInteger rc) {
		if (rc == NSFileHandlingPanelOKButton)
			[self deleteSelectedFile];
	}];
}

-(IBAction)createNewFile:(id)sender
{
	MCNewFileController *nfc = [[MCNewFileController alloc] init];
	nfc.completionHandler = ^(NSString *fname) {
		if (fname.length > 0)
			[self handleNewFile:fname];
	};
	[NSApp beginSheet:nfc.window modalForWindow:self.view.window completionHandler:^(NSInteger idx) {
		//have the block keep a reference of nfc until complete
		[nfc fileName];
	}];
}

-(IBAction)saveFileEdits:(id)sender
{
	if (self.selectedFile.isTextFile)
		[self.selectedFile setLocalEdits:self.editView.string];
}

-(IBAction)showImageDetails:(id)sender
{
	[self.imagePopover close];
	dispatch_async(dispatch_get_main_queue(), ^{
		RCMMultiImageController	*ivc = [[RCMMultiImageController alloc] init];
		[ivc view];
		ivc.availableImages = [[RCImageCache sharedInstance] allImages];
		AppDelegate *del = [TheApp delegate];
		[del showViewController:ivc];
		[ivc setDisplayedImages: self.currentImageGroup];
	});
}

-(IBAction)toggleHand:(id)sender
{
	if ([(NSButton*)sender state] == NSOnState) {
		[self.session raiseHand];
	} else {
		[self.session lowerHand];
	}
}

-(IBAction)toggleMicrophone:(id)sender
{
	[self.audioEngine toggleMicrophone];
}

#pragma mark - meat & potatos

-(void)saveSessionState
{
	RCSavedSession *savedState = self.session.savedSessionState;
	[self.outputController saveSessionState:savedState];
	savedState.currentFile = self.selectedFile;
	if (nil == savedState.currentFile)
		savedState.inputText = self.editView.string;
	[savedState setBoolProperty:self.fileListVisible forKey:@"fileListVisible"];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self.outputController restoreSessionState:savedState];
	if (savedState.currentFile.isTextFile) {
		self.selectedFile = savedState.currentFile;
	} else if ([savedState.inputText length] > 0) {
		self.editView.string = savedState.inputText;
	}
	__fileListInitiallyVisible = [savedState boolPropertyForKey:@"fileListVisible"];
	[[RCImageCache sharedInstance] cacheImagesReferencedInHTML:savedState.consoleHtml];
}

-(void)modeChanged
{
	//our mode changed. that means we possibly need to adjust
	[self setMode:self.session.mode];
}

-(void)handleNewFile:(NSString*)fileName
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	RCFile *file = [RCFile insertInManagedObjectContext:moc];
	RCWorkspace *wspace = self.session.workspace;
	file.name = fileName;
	file.fileContents = @"";
	[wspace addFile:file];
	self.statusMessage = [NSString stringWithFormat:@"Sending %@ to server…", file.name];
	self.busy=YES;
	[[Rc2Server sharedInstance] saveFile:file workspace:wspace completionHandler:^(BOOL success, RCFile *newFile) {
		self.busy=NO;
		if (success) {
			self.fileIdJustImported = newFile.fileId;
			[self.session.workspace refreshFiles];
			[self.fileTableView reloadData];
			self.statusMessage = [NSString stringWithFormat:@"File created on server"];
		} else {
			Rc2LogWarn(@"failed to create file on server: %@", newFile.name);
			self.statusMessage = [NSString stringWithFormat:@"Unknown error creating file on server"];
		}
	}];
}

-(void)handleFileImport:(NSURL*)fileUrl
{
	[(AppDelegate*)[TheApp delegate] handleFileImport:fileUrl
											workspace:self.session.workspace 
									completionHandler:^(RCFile *file)
	 {
		if (file) {
			self.fileIdJustImported = file.fileId;
			[self.session.workspace refreshFilesPerformingBlockBeforeNotification:^{
				if (file.isTextFile) {
					file.fileContents = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:nil];
				}
			}];
			[self.fileTableView reloadData];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				[NSAlert displayAlertWithTitle:@"Upload failed" details:@"An unknown error occurred."];
			});
		}
	 }];
}

-(void)deleteSelectedFile
{
	[[Rc2Server sharedInstance] deleteFile:self.selectedFile workspace:self.session.workspace completionHandler:^(BOOL success, id results)
	{
		if (success)
			self.selectedFile = nil;
		else
			[NSAlert displayAlertWithTitle:@"Error" details:@"An unknown error occurred while deleting the selected file."];
	}];
}

-(void)saveChanges
{
	[self saveSessionState];
	self.selectedFile=nil;
}

-(void)syncFile:(RCFile*)file
{
	ZAssert(file.isTextFile, @"asked to sync non-text file");
	self.statusMessage = [NSString stringWithFormat:@"Saving %@ to server…", file.name];
	self.busy=YES;
	[[Rc2Server sharedInstance] saveFile:file workspace:self.session.workspace completionHandler:^(BOOL success, RCFile *theFile) {
		self.busy=NO;
		if (success) {
			[self.fileTableView reloadData];
			self.statusMessage = [NSString stringWithFormat:@"%@ successfully saved to server", theFile.name];
		} else {
			Rc2LogWarn(@"error syncing file to server:%@", file.name);
			self.statusMessage = [NSString stringWithFormat:@"Unknown error while saving %@ to server:%@", file.name, (NSString*)theFile];
		}
	}];
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
			Rc2LogWarn(@"error preparing workspace:%@", response);
			self.statusMessage = [NSString stringWithFormat:@"Error preparing workspace: (%@)", response];
		}
	}];
}

-(NSString*)escapeForJS:(NSString*)str
{
	if ([str isKindOfClass:[NSString class]]) {
		str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		return [str stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	}
//		return [self.jsQuiteRExp stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@"\\'"];
	return [str description];
}

-(void)setEditViewTextWithHighlighting:(NSAttributedString*)srcStr
{
	id astr = [srcStr mutableCopy];
	[astr addAttributes:self.editView.textAttributes range:NSMakeRange(0, [astr length])];
	if ([self.selectedFile.name hasSuffix:@".Rnw"])
		astr = [[RCMSyntaxHighlighter sharedInstance] syntaxHighlightLatexCode:astr];
	else if ([self.selectedFile.name hasSuffix:@".R"])
		astr = [[RCMSyntaxHighlighter sharedInstance] syntaxHighlightRCode:astr];
	[self.editView.textStorage setAttributedString:astr];
	[self.editView setEditable: self.selectedFile.readOnlyValue ? NO : YES];
}

// adds ".txt" on to the end and copies to a tmp directory that will be cleaned up later
-(NSString*)webTmpFilePath:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSError *err=nil;
	if (nil == self.webTmpFileDirectory) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		[fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *newPath = [[self.webTmpFileDirectory stringByAppendingPathComponent:file.name] stringByAppendingPathExtension:@"txt"];
	if (![fm fileExistsAtPath:file.fileContentsPath]) {
		NSString *fileContents = [[Rc2Server sharedInstance] fetchFileContentsSynchronously:file];
		if (![fileContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
			Rc2LogError(@"failed to write web tmp file:%@", err);
	} else if (![fm copyItemAtPath:file.fileContentsPath toPath:newPath error:&err]) {
		Rc2LogError(@"error copying file:%@", err);
	}
	[fm copyItemAtPath:file.fileContentsPath toPath:newPath error:nil];
	return newPath;
}

#pragma mark - session delegate

-(void)connectionOpened
{
	self.busy=NO;
	self.statusMessage = @"Connected";
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.session requestUserList];
	});
//	[self.audioEngine playDataFromFile:@"/Users/mlilback/Desktop/rc2audio.plist"];
}

-(void)connectionClosed
{
	self.statusMessage = @"Disconnected";
}

-(void)handleWebSocketError:(NSError*)error
{
	[self presentError:error];
}

-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
	NSString *cmd = [dict objectForKey:@"msg"];
	NSString *js=nil;
//	Rc2LogInfo(@"processing ws command: %@", cmd);
	if ([cmd isEqualToString:@"userid"]) {
		js = [NSString stringWithFormat:@"iR.setUserid(%@)", [dict objectForKey:@"userid"]];
	} else if ([cmd isEqualToString:@"echo"]) {
		js = [NSString stringWithFormat:@"iR.echoInput('%@', '%@', %@)", 
			  [self escapeForJS:[dict objectForKey:@"script"]],
			  [self escapeForJS:[dict objectForKey:@"username"]],
			  [self escapeForJS:[dict objectForKey:@"user"]]];
	} else if ([cmd isEqualToString:@"error"]) {
		NSString *errmsg = [[dict objectForKey:@"error"] stringByTrimmingWhitespace];
		errmsg = [self escapeForJS:errmsg];
		if ([errmsg indexOf:@"\n"] > 0) {
			errmsg = [errmsg stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
			js = [NSString stringWithFormat:@"iR.displayFormattedError('%@')", errmsg];
		} else {
			js = [NSString stringWithFormat:@"iR.displayError('%@')", errmsg];
		}
	} else if ([cmd isEqualToString:@"join"]) {
		js = [NSString stringWithFormat:@"iR.userJoinedSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"left"]) {
		js = [NSString stringWithFormat:@"iR.userLeftSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpPath = [dict objectForKey:@"helpPath"];
			NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://rc2.stat.wvu.edu/Rdocs/%@.html", helpPath]];
			[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:helpUrl]];
			js = [NSString stringWithFormat:@"iR.appendHelpCommand('%@', '%@')", 
				  [self escapeForJS:[dict objectForKey:@"helpTopic"]],
				  [self escapeForJS:helpUrl.absoluteString]];
		} else if ([dict objectForKey:@"complexResults"]) {
			js = [NSString stringWithFormat:@"iR.appendComplexResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		} else if ([dict objectForKey:@"json"]) {
			js = [NSString stringWithFormat:@"iR.appendResults(%@)",
				  [self escapeForJS:[dict objectForKey:@"json"]]];
		}
		if ([[dict objectForKey:@"imageUrls"] count] > 0) {
			NSArray *adjustedImages = [[RCImageCache sharedInstance] adjustImageArray:[dict objectForKey:@"imageUrls"]];
			js = [NSString stringWithFormat:@"iR.appendImages(%@)",
				  [adjustedImages JSONRepresentation]];
		}
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		NSNumber *fileid = [dict objectForKey:@"fileId"];
		js = [NSString stringWithFormat:@"iR.appendPdf('%@', %@, '%@')", [self escapeForJS:[dict objectForKey:@"pdfurl"]], fileid,
			  [self escapeForJS:[dict objectForKey:@"filename"]]];
		[self.session.workspace updateFileId:fileid];
	} else if ([cmd isEqualToString:@"sasoutput"]) {
		NSArray *fileInfo = [dict objectForKey:@"files"];
		for (NSDictionary *fd in fileInfo) {
			[self.session.workspace updateFileId:[fd objectForKey:@"fileId"]];
		}
		js = [NSString stringWithFormat:@"iR.appendSasFiles(JSON.parse('%@'))", [self escapeForJS:[fileInfo JSONRepresentation]]];
	}
	if (js) {
		[self.outputController executeJavaScript:js];
		[self.outputController executeJavaScript:@"scroll(0,document.body.scrollHeight)"];
	}
}

-(void)performConsoleAction:(NSString*)action
{
	action = [action stringbyRemovingPercentEscapes];
	NSString *cmd = [NSString stringWithFormat:@"iR.appendConsoleText('%@')", action];
	[self.outputController executeJavaScript:cmd];	
}

-(void)displayImage:(NSString*)imgPath
{
	if ([imgPath hasPrefix:@"/"])
		imgPath = [imgPath substringFromIndex:1];
	if (nil == self.imageController)
		self.imageController = [[RCMImageViewer alloc] init];
	if (nil == self.imagePopover) {
		self.imagePopover = [[NSPopover alloc] init];
		self.imagePopover.behavior = NSPopoverBehaviorSemitransient;
	}
	__unsafe_unretained MacSessionViewController *blockSelf = self;
	self.imagePopover.contentViewController = self.imageController;
	self.imageController.imageArray = self.currentImageGroup;
	self.imageController.workspace = self.session.workspace;
	self.imageController.detailsBlock = ^{
		[blockSelf showImageDetails:nil];	
	};
	NSRect r = NSMakeRect(__curImgPoint.x+16, self.outputController.webView.frame.size.height - __curImgPoint.y - 16, 1, 1);
	[self.imagePopover showRelativeToRect:r ofView:self.outputController.webView preferredEdge:NSMaxXEdge];
	[self.imageController displayImage:[NSNumber numberWithInt:[[imgPath lastPathComponent] intValue]]];
}

-(void)displayFile:(RCFile*)file
{
	self.selectedFile = file;
}

-(void)processBinaryMessage:(NSData*)data
{
	[self.audioEngine processBinaryMessage:data];
}

#pragma mark - web output delegate

-(void)executeConsoleCommand:(NSString*)command
{
	[self.session executeScript:command scriptName:nil];
}

-(void)previewImages:(NSArray*)imageUrls atPoint:(NSPoint)pt
{
	if (nil == imageUrls) {
		//they are no longer over an image preview
		self.currentImageGroup = nil;
		__curImgPoint=NSZeroPoint;
		return;
	}
	NSMutableArray *imgArray = [NSMutableArray arrayWithCapacity:imageUrls.count];
	for (NSString *path in imageUrls) {
		NSString *imgId = [path lastPathComponent];
		RCImage *img = [[RCImageCache sharedInstance] imageWithId:imgId];
		if (img)
			[imgArray addObject:img];
	}
	self.currentImageGroup = imgArray;
	__curImgPoint = pt;
}

-(void)handleImageRequest:(NSURL*)url
{
	if ([url.absoluteString hasSuffix:@".pdf"]) {
		//we want to show the pdf
		NSString *path = [url.absoluteString stringByDeletingPathExtension];
		path = [path substringFromIndex:[path lastIndexOf:@"/"]+1];
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[path integerValue]]];
		[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:file.fileContentsPath]]];
//		RCMPDFViewController *pvc = [[RCMPDFViewController alloc] init];
//		[pvc view]; //load from nib
//		[pvc loadPdf:file.fileContentsPath];
//		[(AppDelegate*)[NSApp delegate] showViewController:pvc];
	} else if ([url.absoluteString hasSuffix:@".png"]) {
		//for now. we may want to handle multiple images at once
		[self displayImage:[url path]];
	} else {
		NSString *filename = url.absoluteString.lastPathComponent;
		//what to do? see if it is an acceptable text file suffix. If so, have webview display it
		if ([[Rc2Server acceptableTextFileSuffixes] containsObject:filename.pathExtension]) {
			NSInteger fid = [[filename stringByDeletingPathExtension] integerValue];
			RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:fid]];
			if (file) {
				NSString *tmpPath = [self webTmpFilePath:file];
				[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:tmpPath]]];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.outputController.view.layer setNeedsDisplay];
				});
			}
		}
	}
}

-(IBAction)contextualHelp:(id)sender
{
	NSString *txt = [self.editView.string substringWithRange:[self.editView selectedRange]];
	if (txt.length > 0)
		[self executeConsoleCommand:[NSString stringWithFormat:@"help(%@)", txt]];
}

#pragma mark - text view delegate

-(void)textDidChange:(NSNotification*)note
{
	NSRange rng = self.editView.selectedRange;
	[self setEditViewTextWithHighlighting:self.editView.attributedString];
	[self.editView setSelectedRange:rng];
}

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

-(NSMenu*)textView:(NSTextView *)view menu:(NSMenu *)menu forEvent:(NSEvent *)event atIndex:(NSUInteger)charIndex
{
	NSInteger idx = -1;
	for (NSMenuItem *anItem in menu.itemArray) {
		if ([[anItem title] rangeOfString:@"Google"].location != NSNotFound) {
			idx = [menu indexOfItem:anItem];
		}
	}
	if (idx >= 0) {
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Lookup in R Help" action:@selector(contextualHelp:) keyEquivalent:@""];
		[mi setEnabled:YES];
		[menu insertItem:mi atIndex:idx];
	}
	return menu;
}

-(void)handleTextViewPrint:(id)sender
{
	NSString *job = @"Untitled";
	if (self.selectedFile)
		job = self.selectedFile.name;
	RCMTextPrintView *printView = [[RCMTextPrintView alloc] init];
	printView.textContent = self.editView.attributedString;
	printView.jobName = job;
	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printView];
	printOp.jobTitle = job;
	[printOp.printInfo setVerticalPagination:NSAutoPagination];
	[printOp runOperation];
}

-(void)recolorText
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self setEditViewTextWithHighlighting:self.editView.attributedString];
	});
}

#pragma mark - table view

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	RCFile *file = [self.session.workspace.files objectAtIndexNoExceptions:[self.fileTableView selectedRow]];
	self.selectedFile = file;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.fileTableView)
		return self.session.workspace.files.count;
	return [self.users count];
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == self.userTableView) {
		NSTableCellView *view = [tableView makeViewWithIdentifier:@"user" owner:nil];
		view.objectValue = [self.users objectAtIndex:row];
		return view;
	}
	RCFile *file = [self.session.workspace.files objectAtIndexNoExceptions:row];
	RCMSessionFileCellView *view = [tableView makeViewWithIdentifier:@"file" owner:nil];
	view.objectValue = file;
	__unsafe_unretained MacSessionViewController *blockSelf = self;
	view.syncFileBlock = ^(RCFile *theFile) {
		[blockSelf syncFile:theFile];
	};
	return view;
}

-(NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	if (self.restrictedMode)
		return tableView.selectedRowIndexes;
	return proposedSelectionIndexes;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	if (aTableView == self.userTableView)
		return NO;
	RCFile *file = [self.session.workspace.files objectAtIndex:rowIndexes.firstIndex];
	NSArray *pitems = ARRAY([NSURL fileURLWithPath:file.fileContentsPath]);
	[pboard writeObjects:pitems];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView == self.userTableView)
		return NO;
	return [MultiFileImporter validateTableViewFileDrop:info];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info existingFiles:self.session.workspace.files 
							 completionHandler:^(NSArray *urls, BOOL replaceExisting)
	 {
		 MultiFileImporter *mfi = [[MultiFileImporter alloc] init];
		 mfi.workspace = self.session.workspace;
		 mfi.replaceExisting = replaceExisting;
		 mfi.fileUrls = urls;
		 AMProgressWindowController *pwc = [mfi prepareProgressWindowWithErrorHandler:^(MultiFileImporter *mfiRef) {
			 [self presentError:mfiRef.lastError modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
		 }];
		 [[NSOperationQueue mainQueue] addOperation:mfi];
		 dispatch_async(dispatch_get_main_queue(), ^{
			 [NSApp beginSheet:pwc.window modalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
		 });
	 }];
	return YES;
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
		if (__selFile.readOnlyValue)
			;
		else if ([__selFile.fileContents isEqualToString:self.editView.string])
			[__selFile setLocalEdits:nil];
		else
			[__selFile setLocalEdits:self.editView.string];
	} else
		self.scratchString = self.editView.string;
	RCFile *oldFile = __selFile;
	NSInteger oldFileIdx = [self.session.workspace.files indexOfObject:oldFile];
	if (oldFileIdx < 0)
		oldFileIdx = 0;
	__selFile = selectedFile;
	if ([selectedFile.name hasSuffix:@".pdf"]) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:selectedFile];
		RunAfterDelay(0.2, ^{
			__selFile=nil;
			[self.fileTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:oldFileIdx] byExtendingSelection:NO];
			[self tableViewSelectionDidChange:nil];
		});
	} else {
		NSString *newTxt = self.scratchString;
		if (selectedFile)
			newTxt = selectedFile.currentContents;
		[self setEditViewTextWithHighlighting:[NSMutableAttributedString attributedStringWithString:newTxt attributes:nil]];
	}
	if (self.session.isClassroomMode && !self.restrictedMode) {
		[self.session sendFileOpened:selectedFile];
	}
}

-(void)setMode:(NSString*)mode
{
	NSString *fancyMode = @"Share Mode";
	if ([mode isEqualToString:kMode_Control])
		fancyMode = @"Control Mode";
	else if ([mode isEqualToString:kMode_Classroom])
		fancyMode = @"Classroom Mode";
	self.modeLabel.stringValue = fancyMode;
	[self.modePopUp selectItemWithTitle:fancyMode];
	self.restrictedMode = ![mode isEqualToString:kMode_Share] && !(self.session.currentUser.master || self.session.currentUser.control);
}

-(NSView*)rightStatusView
{
	return self.rightContainer;
}

-(void)setRestrictedMode:(BOOL)rmode
{
	_restrictedMode = rmode;
	self.outputController.restrictedMode = rmode;
}

-(BOOL)restricted
{
	return self.restrictedMode;
}

@synthesize contentSplitView;
@synthesize fileTableView;
@synthesize outputController;
@synthesize addMenu;
@synthesize fileContainerView;
@synthesize editView;
@synthesize executeButton;
@synthesize scratchString;
@synthesize jsQuiteRExp;
//@synthesize dloadQueue;
@synthesize imagePopover;
@synthesize imageController;
@synthesize currentImageGroup;
@synthesize fileIdJustImported;
@synthesize fullscreenToken;
@synthesize selectedLeftViewIndex;
@synthesize userTableView;
@synthesize users;
@synthesize modePopUp;
@synthesize rightContainer;
@synthesize modeLabel;
@synthesize usersToken;
@synthesize modeChangeToken;
@synthesize audioEngine;
@synthesize backButton;
@synthesize webTmpFileDirectory=_webTmpFileDirectory;
@end

@implementation SessionView
@end
