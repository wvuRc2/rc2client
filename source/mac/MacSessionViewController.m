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
#import "RCVariable.h"
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
#import "MacSessionView.h"

@interface VariableTableHelper : NSObject<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, weak) RCSession *session;
@end

@interface MacSessionViewController() <NSPopoverDelegate> {
	NSPoint __curImgPoint;
	BOOL __didInit;
	BOOL __movingFileList;
	BOOL __fileListInitiallyVisible;
	BOOL __didFirstLoad;
	BOOL __didFirstWindow;
	BOOL __toggledFileViewOnFullScreen;
}
@property (nonatomic, strong) IBOutlet NSButton *backButton;
@property (nonatomic, weak) IBOutlet NSButton *tbFilesButton;
@property (nonatomic, weak) IBOutlet NSButton *tbVarsButton;
@property (nonatomic, weak) IBOutlet NSButton *tbUsersButton;
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, strong) VariableTableHelper *variableHelper;
@property (nonatomic, strong) NSMenu *addMenu;
@property (nonatomic, strong) MCWebOutputController *outputController;
@property (nonatomic, strong) NSArray *fileArray;
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
@property (nonatomic, strong) id variablesVisibleToken;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) NSString *webTmpFileDirectory;
@property (nonatomic, strong) NSWindow *blockingWindow;
@end

@implementation MacSessionViewController

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		NSError *err=nil;
		self.session = aSession;
		self.session.delegate = self;
		self.variableHelper = [[VariableTableHelper alloc] init];
		self.variableHelper.session = aSession;
		self.scratchString=@"";
		self.users = [NSArray array];
		self.fileArray = [self.session.workspace.files sortedArrayUsingDescriptors:ARRAY([NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES])];
		for (RCFile *file in self.fileArray)
			[file updateContentsFromServer];
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
		__unsafe_unretained MacSessionViewController *blockSelf = self;
		self.modeChangeToken = [aSession addObserverForKeyPath:@"mode" task:^(id obj, NSDictionary *change) {
			[blockSelf modeChanged];
		}];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workspaceFilesChanged:) name:RCWorkspaceFilesFetchedNotification object:self.session.workspace];
	}
	return self;
}

-(void)dealloc
{
//	[self.outputController.webView unbind:@"enabled"];
	[self unregisterAllNotificationTokens];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didInit) {
		self.outputController = [[MCWebOutputController alloc] init];
		[self.sessionView embedOutputView:self.outputController.view];
		self.outputController.delegate = (id)self;
		if (!self.session.socketOpen) {
			self.busy = YES;
			self.statusMessage = @"Connecting to server…";
			[self prepareForSession];
		}
//		[self.outputController.webView bind:@"enabled" toObject:self withKeyPath:@"restricted" options:nil];
		self.varTableView.dataSource = self.variableHelper;
		self.varTableView.delegate = self.variableHelper;
		self.addMenu = [[NSMenu alloc] initWithTitle:@"Add a File"];
		[self.addMenu setAutoenablesItems:NO];
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"New File…" action:@selector(createNewFile:) keyEquivalent:@""];
		mi.target = self;
		[mi setEnabled:YES];
		[self.addMenu addItem:mi];
		mi = [[NSMenuItem alloc] initWithTitle:@"Import File…" action:@selector(importFile:) keyEquivalent:@""];
		mi.target = self;
		[self.addMenu addItem:mi];
		self.audioEngine = [[RCAudioChatEngine alloc] init];
		self.audioEngine.session = self.session;

//		NSImage *timg = [NSImage imageNamed:NSImageNameGoLeftTemplate];
//		[timg setSize:NSMakeSize(16, 16)];
//		NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
//		[img lockFocus];
//		[timg drawInRect:NSMakeRect(8, 8, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//		[img unlockFocus];
//		[img setTemplate:YES];
//		self.backButton.image = img;
		
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
					NSUInteger idx = [blockSelf.fileArray indexOfObjectWithValue:blockSelf.fileIdJustImported usingSelector:@selector(fileId)];
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
					if (!blockSelf.sessionView.leftViewVisible) {
						[blockSelf.sessionView toggleLeftView:blockSelf];
						blockSelf->__toggledFileViewOnFullScreen = YES;
					}
				} else if (blockSelf->__toggledFileViewOnFullScreen && blockSelf.sessionView.leftViewVisible) {
					[blockSelf.sessionView toggleLeftView:blockSelf];
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
		self.variablesVisibleToken = [self.sessionView addObserverForKeyPath:@"leftViewVisible" task:^(id obj, NSDictionary *change)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				blockSelf.session.variablesVisible = blockSelf.sessionView.leftViewVisible &&
					blockSelf.selectedLeftViewIndex == 1;
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
			if (self.session.initialFileSelection.isTextFile)
				self.selectedFile = self.session.initialFileSelection;
			self.session.initialFileSelection = nil;
		}
	}
}

-(void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (!__didFirstWindow) {
		if ((self.sessionView.leftViewVisible && !__fileListInitiallyVisible) ||
			(!self.sessionView.leftViewVisible && __fileListInitiallyVisible))
		{
			[self.sessionView toggleLeftView:nil];
		}
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
			[(NSMenuItem*)item setTitle:self.sessionView.leftViewVisible ? @"Hide File List" : @"Show File List"];
		}
		return YES;
	} else if (action == @selector(exportFile:)) {
		return self.selectedFile != nil;
	} else if (action == @selector(importFile:) || action == @selector(createNewFile:)) {
		return self.session.hasWritePerm;
	} else if (action == @selector(saveFileEdits:)) {
		return self.selectedFile.isTextFile && ![self.editView.string isEqualToString:self.selectedFile.currentContents];
	} else if (action == @selector(revert:)) {
		return self.selectedFile.isTextFile && ![self.editView.string isEqualToString:self.selectedFile.fileContents];
	} else if (action == @selector(toggleUsers:)) {
		return YES;
	} else if (action == @selector(changeMode:)) {
		return self.session.currentUser.master;
	} else if (action == @selector(contextualHelp:)) 
		return YES;
	return NO;
}

#pragma mark - actions

-(IBAction)tbTabButtonPressed:(NSButton*)sender
{
	if (sender == self.tbFilesButton) {
		self.tbVarsButton.state = NSOffState;
		self.tbUsersButton.state = NSOffState;
		if (sender.state == NSOnState)
			self.selectedLeftViewIndex = 0;
		else
			[self.sessionView toggleLeftView:sender];
	} else if (sender == self.tbVarsButton) {
		self.tbUsersButton.state = NSOffState;
		self.tbFilesButton.state = NSOffState;
		if (sender.state == NSOnState)
			self.selectedLeftViewIndex = 1;
		else
			[self.sessionView toggleLeftView:sender];
	} else if (sender == self.tbUsersButton) {
		self.tbVarsButton.state = NSOffState;
		self.tbFilesButton.state = NSOffState;
		if (sender.state)
			self.selectedLeftViewIndex = 2;
		else
			[self.sessionView toggleLeftView:sender];
	}
	if (sender.state == NSOnState && !self.sessionView.leftViewVisible)
		[self.sessionView toggleLeftView:sender];
}

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

-(IBAction)executeScript:(id)sender
{
	if ([self.selectedFile.name hasSuffix:@".Rnw"]) {
		[self.session executeSweave:self.selectedFile.name script:self.editView.string];
	} else if ([self.selectedFile.name hasSuffix:@".sas"]) {
		[self.session executeSas:self.selectedFile];
	} else if ([self.selectedFile.name hasSuffix:@".Rmd"]) {
			[self.session executeSweave:self.selectedFile.name script:self.editView.string];
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
	if (self.selectedFile.isTextFile) {
		self.selectedFile.localEdits = self.editView.string;
		[self syncFile:self.selectedFile];
	}
}

-(IBAction)revert:(id)sender
{
	if (self.selectedFile.isTextFile)
		[self setEditViewTextWithHighlighting:[NSAttributedString attributedStringWithString:self.selectedFile.fileContents attributes:nil]];
}

-(IBAction)showImageDetails:(id)sender
{
	[self.imagePopover close];
	dispatch_async(dispatch_get_main_queue(), ^{
		RCMMultiImageController	*ivc = [[RCMMultiImageController alloc] init];
		[ivc view];
		if (_currentImageGroup.count > 0)
			ivc.availableImages = _currentImageGroup;
		else
			ivc.availableImages = [[RCImageCache sharedInstance] allImages];
		AppDelegate *del = [TheApp delegate];
		[del showViewController:ivc];
		[ivc setDisplayedImages: self.currentImageGroup];
	});
}

-(IBAction)refreshVariables:(id)sender
{
	[self.session forceVariableRefresh];
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
	[savedState setBoolProperty:self.sessionView.leftViewVisible forKey:@"fileListVisible"];
	[savedState setProperty:@(self.selectedLeftViewIndex) forKey:@"selLeftViewIdx"];
	[savedState setProperty:[NSNumber numberWithDouble:self.sessionView.editorWidth] forKey:@"editorWidth"];
	[self.sessionView saveSessionState:savedState];
	[savedState.managedObjectContext save:nil];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self.outputController restoreSessionState:savedState];
	if (savedState.currentFile.isTextFile) {
		self.selectedFile = savedState.currentFile;
	} else if ([savedState.inputText length] > 0) {
		self.editView.string = savedState.inputText;
	}
	[self.sessionView restoreSessionState:savedState];
	self.sessionView.editorWidth = [[savedState propertyForKey:@"editorWidth"] doubleValue];
	__fileListInitiallyVisible = [savedState boolPropertyForKey:@"fileListVisible"];
	self.selectedLeftViewIndex = [[savedState propertyForKey:@"selLeftViewIdx"] intValue];
	[self adjustLeftViewButtonsToMatchState];
	[[RCImageCache sharedInstance] cacheImagesReferencedInHTML:savedState.consoleHtml];
}

-(void)adjustLeftViewButtonsToMatchState
{
	self.tbFilesButton.state = NSOffState;
	self.tbVarsButton.state = NSOffState;
	self.tbUsersButton.state = NSOffState;
	if (__fileListInitiallyVisible) {
		if (self.selectedLeftViewIndex == 0)
			self.tbFilesButton.state = NSOnState;
		else if (self.selectedLeftViewIndex == 1)
			self.tbVarsButton.state = NSOnState;
		else
			self.tbUsersButton.state = NSOnState;
	}
}

-(void)modeChanged
{
	//our mode changed. that means we possibly need to adjust
	[self setMode:self.session.mode];
}

-(void)clearJustChangedVariables
{
	for (RCVariable *var in self.session.variables)
		var.justUpdated = NO;
	[self.varTableView reloadData];
}

-(void)workspaceFilesChanged:(NSNotification*)note
{
	self.fileArray = [self.session.workspace.files sortedArrayUsingDescriptors:ARRAY([NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES])];
	[self.fileTableView reloadData];
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
		if (success) {
			self.selectedFile = self.fileArray.firstObject;
		} else
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
	int64_t delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
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
	});
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

-(void)setEditViewTextWithHighlighting:(NSAttributedString*)srcStr
{
	id astr = [srcStr mutableCopy];
	[astr addAttributes:self.editView.textAttributes range:NSMakeRange(0, [astr length])];
	astr = [[RCMSyntaxHighlighter sharedInstance] syntaxHighlightCode:astr ofType:self.selectedFile.name.pathExtension];
	if (astr)
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
	NSString *ext = @"txt";
	if ([file.name hasSuffix:@".html"])
		ext = @"html";
	NSString *newPath = [[self.webTmpFileDirectory stringByAppendingPathComponent:file.name] stringByAppendingPathExtension:ext];
	if ([fm fileExistsAtPath:newPath])
		[fm removeItemAtPath:newPath error:nil];
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
		if (self.selectedLeftViewIndex == 1)
			[self.session forceVariableRefresh];
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

-(NSString*)executeJavascript:(NSString*)js
{
	[self.outputController executeJavaScript:js];
	return [self.outputController executeJavaScript:@"scroll(0,document.body.scrollHeight)"];
}

-(void)loadHelpURL:(NSURL*)url
{
	[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)processWebSocketMessage:(NSDictionary*)dict json:(NSString*)jsonString
{
	NSString *cmd = [dict objectForKey:@"msg"];
	if ([cmd isEqualToString:@"status"]) {
		if ([[dict objectForKey:@"busy"] boolValue])
			self.statusMessage = @"Server status: busy";
		else
			self.statusMessage = @"Server status: idle";
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict count] > 1) {
			for (RCVariable *oldVar in self.session.variables)
				oldVar.justUpdated = NO;
			//not an empty result
			[self variablesUpdated];
		}
	}
}

-(void)performConsoleAction:(NSString*)action
{
	action = [action stringbyRemovingPercentEscapes];
	NSString *cmd = [NSString stringWithFormat:@"iR.appendConsoleText('%@')", action];
	[self.outputController executeJavaScript:cmd];	
}

-(void)setupImageDisplay:(NSArray*)imgArray
{
	if (nil == self.imageController)
		self.imageController = [[RCMImageViewer alloc] init];
	if (nil == self.imagePopover) {
		self.imagePopover = [[NSPopover alloc] init];
		self.imagePopover.behavior = NSPopoverBehaviorSemitransient;
		self.imagePopover.delegate = self;
	}
	__unsafe_unretained MacSessionViewController *blockSelf = self;
	self.imagePopover.contentViewController = self.imageController;
	self.imageController.imageArray = imgArray;
	self.imageController.workspace = self.session.workspace;
	self.imageController.detailsBlock = ^{
		[blockSelf showImageDetails:nil];	
	};
	NSRect r = NSMakeRect(__curImgPoint.x+16, self.outputController.webView.frame.size.height - __curImgPoint.y +40, 1, 1);
	[self.imagePopover showRelativeToRect:r ofView:self.view preferredEdge:NSMaxXEdge];
}


-(void)displayImage:(NSString*)imgPath
{
	if ([imgPath hasPrefix:@"/"])
		imgPath = [imgPath substringFromIndex:1];
	NSString *idStr = [imgPath.lastPathComponent stringByDeletingPathExtension];
	NSArray *imgArray = self.currentImageGroup;
	if (imgArray.count < 1) {
		RCImage *img = [[RCImageCache sharedInstance] imageWithId:idStr];
		imgArray = [NSArray arrayWithObject:img];
	}
	[self setupImageDisplay:imgArray];
	[self.imageController displayImage:[NSNumber numberWithInt:[idStr intValue]]];
}

-(void)displayLinkedFile:(NSString*)urlPath atPoint:(NSPoint)pt
{
	__curImgPoint = pt;
	[self displayLinkedFile:urlPath];
	__curImgPoint = NSZeroPoint;
}

-(void)displayLinkedFile:(NSString*)urlPath
{
	NSString *fileIdStr = urlPath.lastPathComponent.stringByDeletingPathExtension;
	if ([urlPath hasSuffix:@".pdf"]) {
		//we want to show the pdf
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[fileIdStr integerValue]]];
		if (!file.contentsLoaded)
			[file updateContentsFromServer];
		[self.outputController loadLocalFile:file];
		return;
	}
	//a sas file most likely
	NSString *filename = urlPath.lastPathComponent;
	NSString *fileExt = filename.pathExtension;
	//what to do? see if it is an acceptable text file suffix. If so, have webview display it
	if ([[Rc2Server acceptableTextFileSuffixes] containsObject:fileExt]) {
		NSInteger fid = [[filename stringByDeletingPathExtension] integerValue];
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:fid]];
		if (file) {
			[self.outputController loadLocalFile:file];
		}
	} else if ([[Rc2Server acceptableImageFileSuffixes] containsObject:fileExt]) {
		//show as an image
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[fileIdStr integerValue]]];
		if (file) {
			if (!file.contentsLoaded)
				[[Rc2Server sharedInstance] fetchBinaryFileContentsSynchronously:file];
			RCImage *img = [[RCImageCache sharedInstance] loadImageFileIntoCache:file];
			[self setupImageDisplay:ARRAY(img)];
			[self.imageController displayImage:img.imageId];
		}
	}
}

-(void)displayEditorFile:(RCFile*)file
{
	self.selectedFile = file;
}

-(void)workspaceFileUpdated:(RCFile*)file
{
	if (self.selectedFile.fileId.intValue == file.fileId.intValue) {
		//we need to reload the contents of the file
		_selectedFile = nil; //force to treat as new file, i.e. don't save current edits
		self.selectedFile = file;
	}
}

-(void)variablesUpdated
{
	[self.varTableView reloadData];
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
		NSString *imgId = [[path lastPathComponent] stringByDeletingPathExtension];
		RCImage *img = [[RCImageCache sharedInstance] imageWithId:imgId];
		if (img)
			[imgArray addObject:img];
	}
	self.currentImageGroup = imgArray;
	//pt is relative to output view. we need to make relative to our view
	__curImgPoint = [self.view convertPoint:pt fromView:self.outputController.view];
}

-(void)handleImageRequest:(NSURL*)url
{
	NSString *urlStr = url.absoluteString;
	if ([urlStr rangeOfString:@"?"].length > 0) {
		NSRange posRng = [urlStr rangeOfString:@"&pos="];
		if (posRng.length > 0) {
			NSArray *coords = [[urlStr substringFromIndex:posRng.location+5] componentsSeparatedByString:@","];
			__curImgPoint.x = [[coords objectAtIndex:0] integerValue];
			__curImgPoint.y = [[coords objectAtIndex:1] integerValue];
			__curImgPoint = [self.view convertPoint:__curImgPoint fromView:self.outputController.view];
			NSString *imgPath = [urlStr substringToIndex:posRng.location];
			_currentImageGroup = [[RCImageCache sharedInstance] groupImagesForLinkPath:imgPath];
		}
		urlStr = [urlStr substringToIndex:[urlStr rangeOfString:@"?"].location];
	}
	if ([urlStr hasSuffix:@".pdf"]) {
		//we want to show the pdf
		NSString *path = [url.absoluteString stringByDeletingPathExtension];
		path = [path substringFromIndex:[path lastIndexOf:@"/"]+1];
		RCFile *file = [self.session.workspace fileWithId:[NSNumber numberWithInteger:[path integerValue]]];
		[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:file.fileContentsPath]]];
//		RCMPDFViewController *pvc = [[RCMPDFViewController alloc] init];
//		[pvc view]; //load from nib
//		[pvc loadPdf:file.fileContentsPath];
//		[(AppDelegate*)[NSApp delegate] showViewController:pvc];
	} else if ([urlStr hasSuffix:@".png"]) {
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

#pragma mark - image popover delegate

-(void)popoverDidShow:(NSNotification*)note
{
	NSLog(@"popover shown");
}

-(void)popoverDidClose:(NSNotification*)note
{
	NSLog(@"popover closed");
}

- (void)popoverWillShow:(NSNotification *)notification
{
	NSLog(@"popover will show");
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
	if ([notification object] == self.fileTableView) {
		RCFile *file = [self.fileArray objectAtIndexNoExceptions:[self.fileTableView selectedRow]];
		self.selectedFile = file;
	}
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == self.fileTableView)
		return self.fileArray.count;
	if (tableView == self.userTableView)
		return [self.users count];
	if (tableView == self.varTableView)
		return [self.session.variables count];
	return 0;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == self.userTableView) {
		NSTableCellView *view = [tableView makeViewWithIdentifier:@"user" owner:nil];
		view.objectValue = [self.users objectAtIndex:row];
		return view;
	}
	if (tableView == self.fileTableView) {
		RCFile *file = [self.fileArray objectAtIndexNoExceptions:row];
		RCMSessionFileCellView *view = [tableView makeViewWithIdentifier:@"file" owner:nil];
		view.objectValue = file;
		__unsafe_unretained MacSessionViewController *blockSelf = self;
		view.syncFileBlock = ^(RCFile *theFile) {
			[blockSelf syncFile:theFile];
		};
		return view;
	}
	NSTableCellView *view = [tableView makeViewWithIdentifier:@"variable" owner:nil];
//	view.objectValue = [self.users objectAtIndex:row];
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
	if (aTableView != self.fileTableView)
		return NO;
	RCFile *file = [self.fileArray objectAtIndex:rowIndexes.firstIndex];
	NSArray *pitems = ARRAY([NSURL fileURLWithPath:file.fileContentsPath]);
	[pboard writeObjects:pitems];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	if (tableView != self.fileTableView)
		return NO;
	return [MultiFileImporter validateTableViewFileDrop:info];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info existingFiles:self.fileArray 
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

#pragma mark - accessors

-(void)setSession:(RCSession *)session
{
	if (_session == session)
		return;
	if (_session) {
		[_session closeWebSocket];
		_session.delegate=nil;
	}
	_session = session;
}

-(void)setSelectedFile:(RCFile *)selectedFile
{
	if (_selectedFile) {
		if (_selectedFile.readOnlyValue)
			;
		else if ([_selectedFile.fileContents isEqualToString:self.editView.string])
			[_selectedFile setLocalEdits:nil];
		else 
			[_selectedFile setLocalEdits:self.editView.string];
	} else
		self.scratchString = self.editView.string;
	RCFile *oldFile = _selectedFile;
	NSInteger oldFileIdx = [self.fileArray indexOfObject:oldFile];
	if (oldFileIdx == NSNotFound)
		oldFileIdx = 0;
	_selectedFile = selectedFile;
	if (nil == selectedFile) {
		[self setEditViewTextWithHighlighting:nil];
	} else if ([selectedFile.name hasSuffix:@".pdf"]) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:selectedFile];
		RunAfterDelay(0.2, ^{
			_selectedFile=nil;
			[self.fileTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:oldFileIdx] byExtendingSelection:NO];
			[self tableViewSelectionDidChange:nil];
		});
	} else if (selectedFile.isTextFile) {
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

-(void)setBusy:(BOOL)busy
{
	if (self.view.window != nil) {
		if (busy) {
			if (self.blockingWindow == nil) {
				CGRect wRect = self.view.window.frame;
				CGRect cRect = [self.view.window.contentView frame];
				CGRect rect = CGRectMake(wRect.origin.x, wRect.origin.y, cRect.size.width, cRect.size.height);
				self.blockingWindow = [[NSWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
				self.blockingWindow.backgroundColor = [NSColor blackColor];
				[self.blockingWindow setOpaque:NO];
				self.blockingWindow.alphaValue = 0.1;
			}
			[self.blockingWindow orderFront:self];
			[self.view.window addChildWindow:self.blockingWindow ordered:NSWindowAbove];
		} else {
			[self.view.window removeChildWindow:self.blockingWindow];
			[self.blockingWindow orderOut:self];
			self.blockingWindow=nil;
		}
	}
	[super setBusy:busy];
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

-(void)setSelectedLeftViewIndex:(NSInteger)idx
{
	_selectedLeftViewIndex = idx;
	self.session.variablesVisible = self.sessionView.leftViewVisible && idx == 1;
}

-(BOOL)restricted
{
	return self.restrictedMode;
}

-(MacSessionView*)sessionView
{
	return (MacSessionView*)self.view;
}

@end

@implementation VariableTableHelper

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.session.variables.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	RCVariable *var = [self.session.variables objectAtIndex:row];
	if ([tableColumn.identifier isEqualToString:@"name"])
		return var.name;
	return var.description;
}

-(NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return nil;
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	RCVariable *var = [self.session.variables objectAtIndex:row];
	if ([tableColumn.identifier isEqualToString:@"value"] && var.justUpdated) {
		[cell setBackgroundColor:[NSColor greenColor]];
		[cell setDrawsBackground:YES];
	} else {
		[cell setDrawsBackground:NO];
		[cell setBackgroundColor:[NSColor whiteColor]];
		[cell setTextColor:[NSColor blackColor]];
	}
}

-(NSString*)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	RCVariable *var = [self.session.variables objectAtIndex:row];
	if ([tableColumn.identifier isEqualToString:@"value"])
		return var.summary;
	return var.name;
}
@end
