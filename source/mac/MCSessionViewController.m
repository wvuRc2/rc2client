//
//  MCSessionViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCSessionViewController.h"
#import "MCWebOutputController.h"
#import "RCMImageViewer.h"
#import "RCMMultiImageController.h"
#import "RCMTextPrintView.h"
#import "Rc2Server.h"
#import "RCMacToolbarItem.h"
#import "RCWorkspace.h"
#import "RCProject.h"
#import "RCFile.h"
#import "RCImage.h"
#import "RCSessionUser.h"
#import "RCSavedSession.h"
#import "RCVariable.h"
#import "RCMTextView.h"
#import "MCNewFileController.h"
#import "RCMAppConstants.h"
#import "AppDelegate.h"
#import "MultiFileImporter.h"
#import "RCMSyntaxHighlighter.h"
#import "RCAudioChatEngine.h"
#import "RCImageCache.h"
#import "NoodleLineNumberView.h"
#import "MCSessionView.h"
#import "MCSessionFileController.h"
#import "MAKVONotificationCenter.h"
#import "MLReachability.h"

#define logJson 1

@interface VariableTableHelper : NSObject<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, copy) NSArray *data;
@end

@interface MCSessionViewController() <NSPopoverDelegate,MCSessionFileControllerDelegate> {
	NSPoint __curImgPoint;
	BOOL __didInit;
	BOOL __movingFileList;
	BOOL __fileListInitiallyVisible;
	BOOL __didFirstLoad;
	BOOL __didFirstWindow;
	BOOL __toggledFileViewOnFullScreen;
#if logJson
	NSFileHandle *_jsonLog;
#endif
}
@property (nonatomic, strong) IBOutlet NSButton *backButton;
@property (nonatomic, weak) IBOutlet NSButton *tbFilesButton;
@property (nonatomic, weak) IBOutlet NSButton *tbVarsButton;
@property (nonatomic, weak) IBOutlet NSButton *tbUsersButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *fileActionPopUp;
@property (nonatomic, strong) IBOutlet NSView *importAccessoryView;
@property (nonatomic, strong) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, strong) VariableTableHelper *variableHelper;
@property (nonatomic, strong) MCSessionFileController *fileHelper;
@property (nonatomic, strong) NSMenu *addMenu;
@property (nonatomic, strong) MCWebOutputController *outputController;
@property (nonatomic, strong) RCFile *editorFile;
@property (nonatomic, strong) NSPopover *imagePopover;
@property (nonatomic, strong) RCMImageViewer *imageController;
@property (nonatomic, strong) NSArray *currentImageGroup;
@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSNumber *fileIdJustImported;
@property (nonatomic, strong) RCAudioChatEngine *audioEngine;
@property (nonatomic, strong) NSString *webTmpFileDirectory;
@property (nonatomic, strong) NSWindow *blockingWindow;
@property (nonatomic, strong) MLReachability *serverReach;
@property BOOL importToProject;
@property (nonatomic, assign) BOOL reconnecting;
@property (nonatomic, assign) BOOL shouldReconnect;
@end

@implementation MCSessionViewController

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MCSessionViewController" bundle:nil];
	if (self) {
		NSError *err=nil;
		self.session = aSession;
		self.session.delegate = self;
		self.variableHelper = [[VariableTableHelper alloc] init];
		self.users = [NSArray array];
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
		[self observeTarget:aSession keyPath:@"mode" selector:@selector(modeChanged) userInfo:nil options:0];
		NSURL *serverUrl = [NSURL URLWithString:[[Rc2Server sharedInstance] websocketUrl]];
		self.serverReach = [MLReachability reachabilityWithHostname:serverUrl.host];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kMLReachabilityChangedNotification object:self.serverReach];
		[self.serverReach startNotifier];
#if logJson
		_jsonLog = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/jsonLog.txt"];
		NSLog(@"opened log %@", _jsonLog);
#endif
	}
	return self;
}

-(void)dealloc
{
#if logJson
	_jsonLog=nil;
#endif
	self.outputController=nil; //we were getting binding errors because the text field was bound to us and we were being dealloc'd first.
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
		self.varTableView.dataSource = self.variableHelper;
		self.varTableView.delegate = self.variableHelper;
		self.fileHelper = [[MCSessionFileController alloc] initWithSession:self.session tableView:self.fileTableView delegate:self];
		self.fileActionPopUp.menu.delegate = self.fileHelper;
		self.fileTableView.menu = self.fileActionPopUp.menu;
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

		//line numbers
		NoodleLineNumberView *lnv = [[NoodleLineNumberView alloc] initWithScrollView:self.editView.enclosingScrollView];
		[self.editView.enclosingScrollView setVerticalRulerView:lnv];
		[self.editView.enclosingScrollView setRulersVisible:YES];
		
		//caches
		__unsafe_unretained MCSessionViewController *blockSelf = self;
		[self observeTarget:self.sessionView keyPath:@"leftViewVisible" options:0 block:^(MAKVONotification *notification) {
			blockSelf.session.variablesVisible = blockSelf.sessionView.leftViewVisible &&
			blockSelf.selectedLeftViewIndex == 1;
			[blockSelf adjustLeftViewButtonsToMatchState:NO];
		}];
		[self observeTarget:[NSApp delegate] keyPath:@"isFullScreen" options:0 block:^(MAKVONotification *notification) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if ([notification.target isFullScreen]) {
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
		[self observeTarget:self.session keyPath:@"users" options:0 block:^(MAKVONotification *notification) {
			dispatch_async(dispatch_get_main_queue(), ^{
				blockSelf.users = blockSelf.session.users;
				[blockSelf.userTableView reloadData];
			});
		}];
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
				self.fileHelper.selectedFile = self.session.initialFileSelection;
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
	RCFile *selFile = self.editorFile;
	if (action == @selector(toggleLeftSideView:)) {
		if ([(id)item isKindOfClass:[NSMenuItem class]]) {
			//adjust the title
			[(NSMenuItem*)item setTitle:self.sessionView.leftViewVisible ? @"Hide Left View" : @"Show Left View"];
		}
		return YES;
	} else if (action == @selector(exportFile:)) {
		return selFile != nil;
	} else if (action == @selector(importFile:) || action == @selector(createNewFile:)) {
		return self.session.hasWritePerm;
	} else if (action == @selector(saveFileEdits:)) {
		return selFile.isTextFile && ![self.editView.string isEqualToString:selFile.currentContents];
	} else if (action == @selector(revert:)) {
		return selFile.isTextFile && ![self.editView.string isEqualToString:selFile.fileContents];
	} else if (action == @selector(toggleUsers:)) {
		return YES;
	} else if (action == @selector(changeMode:)) {
		return self.session.currentUser.master;
	} else if (action == @selector(toggleFiles:)) {
		if (self.selectedLeftViewIndex == 0)
			return NO;
	} else if (action == @selector(toggleVariables:)) {
		if (self.selectedLeftViewIndex == 1)
			return NO;
	} else if (action == @selector(toggleUsers:)) {
		if (self.selectedLeftViewIndex == 2)
			return NO;
	} else if (action == @selector(contextualHelp:)) {
		return YES;
	} else if (action == @selector(executeCurrentLine:)) {
		return YES;
	} return NO;
}

#pragma mark - actions

-(IBAction)toggleLeftSideView:(id)sender
{
	[self.sessionView toggleLeftView:sender];
}

-(IBAction)toggleFiles:(id)sender
{
	[self tbTabButtonPressed:self.tbFilesButton];
}

-(IBAction)toggleUsers:(id)sender
{
	[self tbTabButtonPressed:self.tbUsersButton];
}

-(IBAction)toggleVariables:(id)sender
{
	[self tbTabButtonPressed:self.tbVarsButton];
}

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
	RCFile *selFile = self.editorFile;
	if ([selFile.name hasSuffix:@".Rnw"]) {
		[self.session executeScriptFile:selFile];
	} else if ([selFile.name hasSuffix:@".sas"]) {
		[self.session executeSas:selFile];
	} else if ([selFile.name hasSuffix:@".Rmd"]) {
			[self.session executeScriptFile:selFile];
	} else {
		[self.session executeScript:self.editView.string scriptName:selFile.name];
	}
}

-(IBAction)executeCurrentLine:(id)sender
{
	NSString *str = self.editView.string;
	NSRange rng = [str lineRangeForRange:self.editView.selectedRange];
	NSString *cmd = [str substringWithRange:rng];
	[self.session executeScript:cmd scriptName:nil];

}

-(IBAction)exportFile:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	RCFile *selFile = self.fileHelper.selectedFile;
	[savePanel setNameFieldStringValue:selFile.name];
	[savePanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		NSError *err=nil;
		if (selFile.isTextFile) {
			[selFile.currentContents writeToURL:savePanel.URL atomically:YES encoding:NSUTF8StringEncoding error:&err];
		} else {
			[[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:selFile.fileContentsPath]
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
	self.importToProject = NO;
	openPanel.accessoryView = self.importAccessoryView;
	[openPanel setAllowedFileTypes:[Rc2Server acceptableImportFileSuffixes]];
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		[openPanel orderOut:nil];
		if (NSFileHandlingPanelCancelButton == result)
			return;
		[self handleFileImport:[[openPanel URLs] firstObject]];
	}];
}

-(IBAction)renameFile:(id)sender
{
	RCFile *file = self.fileHelper.selectedFile;
	if ([file isKindOfClass:[RCProject class]])
		return;
	[self.fileHelper editSelectedFilename];
}

-(IBAction)duplicateFile:(id)sender
{
	
}

-(IBAction)deleteFile:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Delete File?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Are you sure you want to delete the file \"%@\"? This action can not be undone.", self.fileHelper.selectedFile.name];
	[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSAlert *theAlert, NSInteger rc) {
		if (rc == NSFileHandlingPanelOKButton)
			[self deleteSelectedFile];
	}];
}

-(IBAction)createNewFile:(id)sender
{
	MCNewFileController *nfc = [[MCNewFileController alloc] init];
	__weak MCNewFileController *weakNfc = nfc;
	nfc.completionHandler = ^(NSString *fname) {
		[NSApp endSheet:weakNfc.window];
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
	RCFile *selFile = self.editorFile;
	if (selFile.isTextFile) {
		selFile.localEdits = self.editView.string;
		[self syncFile:selFile];
	}
}

-(IBAction)revert:(id)sender
{
	RCFile *selFile = self.editorFile;
	if (selFile.isTextFile)
		[self setEditViewTextWithHighlighting:[NSAttributedString attributedStringWithString:selFile.fileContents attributes:nil]];
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
	savedState.currentFile = self.editorFile;
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
		self.fileHelper.selectedFile = savedState.currentFile;
	} else if ([savedState.inputText length] > 0) {
		self.editView.string = savedState.inputText;
	}
	[self.sessionView restoreSessionState:savedState];
	self.sessionView.editorWidth = [[savedState propertyForKey:@"editorWidth"] doubleValue];
	__fileListInitiallyVisible = [savedState boolPropertyForKey:@"fileListVisible"];
	self.selectedLeftViewIndex = [[savedState propertyForKey:@"selLeftViewIdx"] intValue];
	[self adjustLeftViewButtonsToMatchState:YES];
	[[RCImageCache sharedInstance] cacheImagesReferencedInHTML:savedState.consoleHtml];
}

-(void)adjustLeftViewButtonsToMatchState:(BOOL)forTheFirstTime
{
	self.tbFilesButton.state = NSOffState;
	self.tbVarsButton.state = NSOffState;
	self.tbUsersButton.state = NSOffState;
	if (forTheFirstTime) {
		if (__fileListInitiallyVisible) {
			if (self.selectedLeftViewIndex == 0)
				self.tbFilesButton.state = NSOnState;
			else if (self.selectedLeftViewIndex == 1)
				self.tbVarsButton.state = NSOnState;
			else
				self.tbUsersButton.state = NSOnState;
		}
	} else {
		if (self.sessionView.leftViewVisible) {
			if (self.selectedLeftViewIndex == 0)
				self.tbFilesButton.state = NSOnState;
			else if (self.selectedLeftViewIndex == 1)
				self.tbVarsButton.state = NSOnState;
			else
				self.tbUsersButton.state = NSOnState;
		}
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
	[[Rc2Server sharedInstance] saveFile:file toContainer:wspace completionHandler:^(BOOL success, RCFile *newFile) {
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
	id<RCFileContainer> container = self.session.workspace;
	if (self.importToProject)
		container = self.session.workspace.project;
	[[Rc2Server sharedInstance] importFile:fileUrl toContainer:container completionHandler:^(BOOL success, RCFile *file) {
		if (success) {
			self.fileIdJustImported = file.fileId;
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
	[[Rc2Server sharedInstance] deleteFile:self.fileHelper.selectedFile container:self.session.workspace completionHandler:^(BOOL success, id results)
	{
		if (success) {
			self.fileHelper.selectedFile = nil;
			[self.fileHelper updateFileArray];
		} else
			[NSAlert displayAlertWithTitle:@"Error" details:@"An unknown error occurred while deleting the selected file."];
	}];
}

-(void)saveChanges
{
	[self saveSessionState];
//	self.fileHelper.selectedFile=nil;
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
	if (nil == srcStr || nil == self.editorFile) {
		self.editView.string = @"";
		return;
	}
	id astr = [srcStr mutableCopy];
	if (astr == nil)
		astr = [NSMutableAttributedString attributedStringWithString:@"" attributes:nil];
	[astr addAttributes:self.editView.textAttributes range:NSMakeRange(0, [astr length])];
	astr = [[RCMSyntaxHighlighter sharedInstance] syntaxHighlightCode:astr ofType:self.editorFile.name.pathExtension];
	if (astr)
		[self.editView.textStorage setAttributedString:astr];
	[self.editView setEditable: !self.restrictedMode && (self.editorFile.readOnlyValue) ? NO : YES];
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

-(void)reachabilityChanged:(NSNotification*)note
{
	if (self.serverReach.isReachable) {
		if (!_session.socketOpen && !self.reconnecting && self.shouldReconnect) {
			self.reconnecting=YES;
			self.busy=YES;
			self.statusMessage = @"Reconnecting…";
			RunAfterDelay(0.2, ^{
				[self.session startWebSocket];
			});
		}
	} else {
		self.busy=YES;
		self.statusMessage = @"Network unavailable";
	}
}


#pragma mark - file helper delegate

-(void)syncFile:(RCFile*)file
{
	ZAssert(file.isTextFile, @"asked to sync non-text file");
	self.statusMessage = [NSString stringWithFormat:@"Saving %@ to server…", file.name];
	self.busy=YES;
	int64_t delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[Rc2Server sharedInstance] saveFile:file toContainer:self.session.workspace completionHandler:^(BOOL success, RCFile *theFile) {
			self.busy=NO;
			if (success) {
				[self.fileTableView reloadData];
				self.statusMessage = [NSString stringWithFormat:@"%@ successfully saved to server", theFile.name];
				//update display of html files
				if (file == self.editorFile && [file.fileContentsPath.pathExtension isEqualToString:@"html"])
					[self.outputController loadLocalFile:file];
			} else {
				Rc2LogWarn(@"error syncing file to server:%@", file.name);
				self.statusMessage = [NSString stringWithFormat:@"Unknown error while saving %@ to server:%@", file.name, (NSString*)theFile];
			}
		}];
	});
}

-(void)fileSelectionChanged:(RCFile*)selectedFile oldSelection:(RCFile*)oldFile
{
	if (oldFile) {
		if (oldFile.readOnlyValue)
			;
		else if ([oldFile.fileContents isEqualToString:self.editView.string])
			[oldFile setLocalEdits:nil];
		else
			[oldFile setLocalEdits:self.editView.string];
	}
	if (nil == selectedFile) {
		self.editorFile=nil;
		[self setEditViewTextWithHighlighting:nil];
	} else if (selectedFile.isTextFile) {
		self.editorFile = selectedFile;
		[self setEditViewTextWithHighlighting:[NSMutableAttributedString attributedStringWithString:selectedFile.currentContents attributes:nil]];
		//html files are edited and viewed
		if ([selectedFile.fileContentsPath.pathExtension isEqualToString:@"html"])
			[self.outputController loadLocalFile:selectedFile];
	} else {
		[self.outputController loadLocalFile:selectedFile];
	}
	if (self.session.isClassroomMode && !self.restrictedMode) {
		[self.session sendFileOpened:selectedFile fullscreen:NO];
	}
}

-(void)renameFile:(RCFile*)file to:(NSString*)newName
{
	NSLog(@"should change file %@ to %@", file.name, newName);
	self.busy = YES;
	self.statusMessage = [NSString stringWithFormat:@"Renaming %@…", newName];
	[[Rc2Server sharedInstance] renameFile:file toName:newName completionHandler:^(BOOL success, id rsp) {
		self.busy = NO;
		self.statusMessage=nil;
		if (!success) {
			[self.view presentError:[NSError errorWithDomain:@"Rc2" code:-1 userInfo:@{NSLocalizedDescriptionKey:rsp}] modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
		}
		[self.fileHelper updateFileArray];
	}];
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
	if (!self.reconnecting)
		self.shouldReconnect=YES;
	self.reconnecting=NO;
}

-(void)connectionClosed
{
	self.statusMessage = @"Disconnected";
}

-(void)handleWebSocketError:(NSError*)error
{
	if ([error.domain isEqualToString:NSPOSIXErrorDomain] && error.code == ENOTCONN)
		return;
	NSLog(@"connection error:%@", error);
	if (!self.isBusy)
		[self presentError:error];
	if (self.reconnecting) {
		self.reconnecting=NO;
		self.shouldReconnect=NO;
	}
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
#if logJson
	NSString *log = [jsonString stringByAppendingString:@"\n\n"];
	[_jsonLog writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
#endif
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
	__weak MCSessionViewController *blockSelf = self;
	self.imagePopover.contentViewController = self.imageController;
	self.imageController.imageArray = imgArray;
	self.imageController.workspace = self.session.workspace;
	self.imageController.detailsBlock = ^{
		[blockSelf showImageDetails:nil];	
	};
	NSRect r = NSMakeRect(__curImgPoint.x+16, abs(self.outputController.webView.frame.size.height - __curImgPoint.y +40), 1, 1);
	if (r.origin.y < 100)
		r.origin.y = 100;
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
			[file updateContentsFromServer:^(NSInteger success) {
				if (success)
					[self.outputController loadLocalFile:file];
			}];
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

-(void)workspaceFileUpdated:(RCFile*)file
{
	if (self.fileHelper.selectedFile.fileId.intValue == file.fileId.intValue) {
		//we need to reload the contents of the file
		self.fileHelper.selectedFile = file;
	}
}

-(void)displayEditorFile:(RCFile*)file
{
	self.fileHelper.selectedFile = file;
}

-(void)variablesUpdated
{
	NSMutableArray *ma = [NSMutableArray arrayWithCapacity:self.session.variables.count + 5];
	NSMutableArray *data = [NSMutableArray array];
	NSMutableArray *values = [NSMutableArray array];
	NSMutableArray *funcs = [NSMutableArray array];
	for (RCVariable *var in self.session.variables) {
		if (var.treatAsContainerType)
			[data addObject:var];
		else if (var.type == eVarType_Function)
			[funcs addObject:var];
		else
			[values addObject:var];
	}
	if (values.count > 0) {
		[ma addObject:@"Values"];
		[ma addObjectsFromArray:values];
	}
	if (data.count > 0) {
		[ma addObject:@"Data"];
		[ma addObjectsFromArray:data];
	}
	if (funcs.count > 0) {
		[ma addObject:@"Functions"];
		[ma addObjectsFromArray:funcs];
	}
	self.variableHelper.data = ma;
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
	//when we set to nil, the range changes. should never happen unless we were editable when shouldn't have been
	if (rng.location <= self.editView.textStorage.length)
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
	BOOL addedItems = NO;
	for (NSMenuItem *anItem in menu.itemArray) {
		if ([anItem action] == @selector(cut:))
			idx = [menu indexOfItem:anItem];
	}
	if (idx >= 0) {
		if (self.editView.selectedRange.length > 0) {
			NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"Lookup in R Help" action:@selector(contextualHelp:) keyEquivalent:@""];
			[mi setEnabled:YES];
			[menu insertItem:mi atIndex:idx++];
			addedItems = YES;
		}
		NSRange selRng = view.selectedRange;
		NSRange rng = selRng;
		if (rng.length == 0)
			rng = [view.string lineRangeForRange:rng];
		NSString *selText = [[view.string substringWithRange:rng] stringByTrimmingWhitespace];
		if (selText.length > 0) {
			NSString *title = selRng.length > 0 ? @"Run Selection" : @"Run Line";
			NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:title action:@selector(executeCurrentLine:) keyEquivalent:@""];
			[mi setEnabled:YES];
			[menu insertItem:mi atIndex:idx++];
			addedItems = YES;
		}
		if (addedItems)
			[menu insertItem:[NSMenuItem separatorItem] atIndex:idx];
	}
	return menu;
}

-(void)handleTextViewPrint:(id)sender
{
	NSString *job = @"Untitled";
	if (self.editorFile)
		job = self.editorFile.name;
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

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
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

-(MCSessionView*)sessionView
{
	return (MCSessionView*)self.view;
}

@end

@implementation VariableTableHelper

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.data.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	RCVariable *var = [self.data objectAtIndex:row];
	BOOL grpRow = [var isKindOfClass:[NSString class]];
	BOOL isVal = [tableColumn.identifier isEqualToString:@"value"];
	NSTableCellView *view = [tableView makeViewWithIdentifier:isVal ? @"varValueView" : @"varNameView" owner:self];
	view.textField.stringValue = [tableColumn.identifier isEqualToString:@"name"] ? [var name] : [var description];
	if (!grpRow && isVal) {
		if ([var justUpdated]) {
			[view.textField setBackgroundColor:[NSColor greenColor]];
			[view.textField setDrawsBackground:YES];
		} else {
			[view.textField setBackgroundColor:[NSColor whiteColor]];
			[view.textField setDrawsBackground:NO];
		}
		if (isVal && !grpRow) {
			view.textField.toolTip = [var summary];
		} else {
			view.textField.toolTip = @"";
		}
	}
	return view;
}

-(NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return nil;
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id var = [self.data objectAtIndex:row];
	if ([tableColumn.identifier isEqualToString:@"value"] && ![var isKindOfClass:[NSString class]] && [var justUpdated]) {
		[cell setBackgroundColor:[NSColor greenColor]];
		[cell setDrawsBackground:YES];
	} else {
		[cell setDrawsBackground:NO];
		[cell setBackgroundColor:[NSColor whiteColor]];
		[cell setTextColor:[NSColor blackColor]];
	}
}

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
	return [[self.data objectAtIndex:row] isKindOfClass:[NSString class]];
}

-(NSString*)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	RCVariable *var = [self.data objectAtIndex:row];
	if ([tableColumn.identifier isEqualToString:@"value"])
		return var.summary;
	return var.name;
}
@end
