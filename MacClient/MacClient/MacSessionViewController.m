//
//  MacSessionViewController.m
//  MacClient
//
//  Created by Mark Lilback on 10/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
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

@interface MacSessionViewController() {
	AudioQueueRef _inputQueue, _outputQueue;
	AudioStreamBasicDescription _audioDesc;
	CGFloat __fileListWidth;
	NSPoint __curImgPoint;
	BOOL _recordingOn;
	BOOL __didInit;
	BOOL __movingFileList;
	BOOL __fileListInitiallyVisible;
	BOOL __didFirstLoad;
	BOOL __didFirstWindow;
	BOOL __toggledFileViewOnFullScreen;
}
@property (nonatomic, retain) NSRegularExpression *jsQuiteRExp;
@property (nonatomic, retain) NSString *imgCachePath;
@property (nonatomic, retain) NSMutableDictionary *imgCache;
@property (nonatomic, retain) NSOperationQueue *dloadQueue;
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
@property (nonatomic, strong) NSMutableArray *audioQueue;
-(void)prepareForSession;
-(void)completeSessionStartup:(id)response;
-(NSString*)escapeForJS:(NSString*)str;
-(NSArray*)adjustImageArray:(NSArray*)inArray;
-(void)cacheImages:(NSArray*)urls;
-(void)cacheImagesReferencedInHTML:(NSString*)html;
-(BOOL)loadImageIntoCache:(NSString*)imgPath;
-(void)handleFileImport:(NSURL*)fileUrl;
-(void)handleNewFile:(NSString*)fileName;
-(BOOL)fileListVisible;
-(void)syncFile:(RCFile*)file;
-(void)setMode:(NSString*)mode;
-(void)modeChanged;
-(void)initializeRecording;
-(void)initializeAudioOut;
-(void)tearDownAudio;
@end

static void MyAudioInputCallback(void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer,
								 const AudioTimeStamp *inStartTIme, UInt32 inNumPackets,
								 const AudioStreamPacketDescription *inPacketDesc);

static void MyOutputCallback(void *inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inCompleteAQBuffer);
static void MyAudioPropertyListener(void *inUserData, AudioQueueRef queue, AudioQueuePropertyID property);
static Boolean IsQueueRunning(AudioQueueRef queue);

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
	[self tearDownAudio];
	self.contentSplitView.delegate=nil;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didInit) {
		NSError *err=nil;
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
		self.addMenu = [[NSMenu alloc] initWithTitle:@""];
		//read this instead of hard-coding a value that chould change in the nib
		__fileListWidth = self.contentSplitView.frame.origin.x;
		//caches
		NSFileManager *fm = [[NSFileManager alloc] init];
		NSURL *cacheUrl = [NSURL URLWithString:[NSApp thisApplicationsCacheFolder]];
		cacheUrl = [cacheUrl URLByAppendingPathComponent:@"Rimages"];
		if (![fm fileExistsAtPath:cacheUrl.path]) {
			BOOL result = [fm createDirectoryAtPath:[cacheUrl path]
						withIntermediateDirectories:YES
										 attributes:nil
											  error:&err];
			ZAssert(result, @"failed to create img cache directory: %@", [err localizedDescription]);
		}
		self.imgCachePath = [cacheUrl path];
		self.imgCache = [NSMutableDictionary dictionary];
		self.dloadQueue = [[NSOperationQueue alloc] init];
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
	if (!__didFirstLoad) {
		NSToolbar *tbar = [NSApp valueForKeyPath:@"delegate.mainWindowController.window.toolbar"];
		RCMacToolbarItem *ti = [tbar.items firstObjectWithValue:@"add" forKey:@"itemIdentifier"];
		if (newSuperview) {
			RCSavedSession *savedState = self.session.savedSessionState;
			[self restoreSessionState:savedState];
			[ti pushActionMenu:self.addMenu];
		} else {
			[ti popActionMenu:self.addMenu];
		}
		__didFirstLoad=YES;
	} else if (newSuperview == nil) {
		[self saveSessionState];
		[self tearDownAudio];
	}
}

-(void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (!__didFirstWindow) {
		if (self.fileListVisible != __fileListInitiallyVisible)
			[self toggleFileList:nil];
		self.selectedFile = self.session.initialFileSelection;
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
	}
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

-(IBAction)toggleUsers:(id)sender
{
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
	} else {
		[self.session executeScript:self.editView.string];
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

-(IBAction)createNewFile:(id)sender
{
	MCNewFileController *nfc = [[MCNewFileController alloc] init];
	nfc.completionHandler = ^(NSString *fname) {
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
		ivc.availableImages = self.imgCache.allValues;
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
	ZAssert(_recordingOn != [(NSButton*)sender state], @"recording state out of sync with UI");
	if (nil == _inputQueue)
		[self initializeRecording];
	if (_recordingOn) {
		//pause it then
		AudioQueuePause(_inputQueue);
	} else {
		//start it
		OSStatus status = AudioQueueStart(_inputQueue, NULL);
		if (noErr != status)
			NSLog(@"error starting input queue: %d", status);
	}
	_recordingOn = !_recordingOn;
}

#pragma mark - voice chat

-(void)initializeRecording
{
	if (_inputQueue)
		return;
	//get the audio format info
	if (0 == _audioDesc.mFormatID) {
		_audioDesc.mFormatID = kAudioFormatiLBC;
		UInt32 propSize = sizeof(AudioStreamBasicDescription);
		AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &_audioDesc);
	}
	OSStatus err = AudioQueueNewInput(&_audioDesc, MyAudioInputCallback, (__bridge void*)self, NULL, NULL, 0, &_inputQueue);
	if (err != noErr) {
		Rc2LogError(@"failed to create input audio queue: %d", err);
		//TODO: inform user
	}
	for (int i=0; i < 3; i++) {
		AudioQueueBufferRef buffer;
		AudioQueueAllocateBuffer(_inputQueue, 950, &buffer);
		AudioQueueEnqueueBuffer(_inputQueue, buffer, 0, NULL);
	}
	AudioQueueAddPropertyListener(_inputQueue, kAudioQueueProperty_IsRunning, MyAudioPropertyListener, (__bridge void*)self);
}

-(void)initializeAudioOut
{
	if (_outputQueue)
		return;
	if (nil == self.audioQueue)
		self.audioQueue = [NSMutableArray array];
	if (0 == _audioDesc.mFormatID) {
		_audioDesc.mFormatID = kAudioFormatiLBC;
		UInt32 propSize = sizeof(AudioStreamBasicDescription);
		AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &_audioDesc);
	}
	OSStatus err = AudioQueueNewOutput(&_audioDesc, MyOutputCallback, (__bridge void*)self, NULL, NULL, 0, &_outputQueue);
	if (noErr != err) {
		//TODO: report error
		Rc2LogError(@"error starting audio output queue:%d", err);
	}
}

-(void)resetOutputQueue
{
	AudioQueueBufferRef buffers[3];
	for (int i=0; i < 3; i++) {
		AudioQueueAllocateBuffer(_outputQueue, 950, &buffers[i]);
		MyOutputCallback((__bridge void*)self, _outputQueue, buffers[i]);
	}
	AudioQueueStart(_outputQueue, NULL);
}

-(void)outOfAudioOutputData
{
	AudioQueueStop(_outputQueue, false);
}

-(NSData*)popNextAudioOutPacket
{
	NSData *d = nil;
	if (self.audioQueue.count < 1)
		return nil;
	@synchronized (self) {
		d = [self.audioQueue lastObject];
		[self.audioQueue removeLastObject];
		if (self.audioQueue.count < 1) {
			[self outOfAudioOutputData];
		}
	}
	return d;
}

-(void)tearDownAudio
{
	if (_inputQueue) {
		AudioQueueRemovePropertyListener(_inputQueue, kAudioQueueProperty_IsRunning, MyAudioPropertyListener, (__bridge void*)self);
		AudioQueueStop(_inputQueue, true);
		AudioQueueDispose(_inputQueue, true);
		_inputQueue=nil;
	}
	if (_outputQueue) {
		AudioQueueStop(_outputQueue, true);
		AudioQueueDispose(_outputQueue, true);
		_outputQueue=nil;
	}
}

-(void)processRecordedData:(AudioQueueBufferRef)inBuffer
{
	if (inBuffer->mAudioDataByteSize > 0) {
		NSData *audioData = [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.session sendAudioInput:audioData];
		});
	}
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
	[self cacheImagesReferencedInHTML:savedState.consoleHtml];
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
			Rc2LogWarn(@"error syncing file to server:%@", theFile.name);
			self.statusMessage = [NSString stringWithFormat:@"Unknown error while saving %@ to server", theFile.name];
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
	if ([str isKindOfClass:[NSString class]])
		return [str stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
//		return [self.jsQuiteRExp stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@"\\'"];
	return [str description];
}

-(BOOL)loadImageIntoCache:(NSString*)imgPath
{
	imgPath = imgPath.lastPathComponent;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *fpath = [self.imgCachePath stringByAppendingPathComponent:imgPath];
	if (![fm fileExistsAtPath:fpath])
		return NO;
	RCImage *img = [[RCImage alloc] initWithPath:fpath];
	img.name = [imgPath stringbyRemovingPercentEscapes];
	if ([img.name indexOf:@"#"] != NSNotFound)
		img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
	[self.imgCache setObject:img forKey:imgPath];
	return YES;
}

-(void)cacheImagesReferencedInHTML:(NSString*)html
{
	if (nil == html)
		return;
	NSError *err=nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"rc2img:///iR/images/([^\\.]+\\.png)" options:0 error:&err];
	ZAssert(nil == err, @"error compiling regex: %@", [err localizedDescription]);
	__unsafe_unretained MacSessionViewController *blockSelf = self;
	[regex enumerateMatchesInString:html options:0 range:NSMakeRange(0, [html length]) 
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) 
	 {
		 NSString *fname = [html substringWithRange:[match rangeAtIndex:1]];
		 [blockSelf loadImageIntoCache:fname];
	 }];
}


-(void)cacheImages:(NSArray*)urls
{
	for (NSString *str in urls) {
		NSString *fname = [str lastPathComponent];
		NSString *imgPath = [self.imgCachePath stringByAppendingPathComponent:fname];
		NSURL *url = [NSURL URLWithString:str];
		ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
		[req setDownloadDestinationPath: imgPath];
		__unsafe_unretained MacSessionViewController *blockSelf = self;
		[req setCompletionBlock:^{
			RCImage *img = [[RCImage alloc] initWithPath:imgPath];
			img.name = [fname stringbyRemovingPercentEscapes];
			if ([img.name indexOf:@"#"] != NSNotFound)
				img.name = [img.name substringFromIndex:[img.name indexOf:@"#"]+1];
			[blockSelf.imgCache setObject:img forKey:fname];
		}];
		[self.dloadQueue addOperation:req];
	}
}

-(NSArray*)adjustImageArray:(NSArray*)inArray
{
	NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	NSMutableArray *fetchArray = [NSMutableArray arrayWithCapacity:[inArray count]];
	NSString *baseUrl = [[Rc2Server sharedInstance] baseUrl];
	for (NSString *aUrl in inArray) {
		[outArray addObject:[NSString stringWithFormat:@"rc2img://%@", aUrl]];
		[fetchArray addObject:[NSString stringWithFormat:@"%@%@", baseUrl, [aUrl substringFromIndex:1]]];
	}
	//now need to fetch images in background
	[self cacheImages:fetchArray];
	return outArray;
}

#pragma mark - session delegate

-(void)connectionOpened
{
	self.busy=NO;
	self.statusMessage = @"Connected";
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.session requestUserList];
	});
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
	Rc2LogInfo(@"processing ws command: %@", cmd);
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
		js = [NSString stringWithFormat:@"iR.displayError('%@')", errmsg];
	} else if ([cmd isEqualToString:@"join"]) {
		js = [NSString stringWithFormat:@"iR.userJoinedSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"left"]) {
		js = [NSString stringWithFormat:@"iR.userLeftSession('%@', '%@')", 
			  [self escapeForJS:[dict objectForKey:@"user"]],
			  [self escapeForJS:[dict objectForKey:@"userid"]]];
	} else if ([cmd isEqualToString:@"userlist"]) {
		js = [NSString stringWithFormat:@"iR.updateUserList(JSON.parse('%@'))", 
			  [[[dict objectForKey:@"data"] objectForKey:@"users"] JSONRepresentation]];
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
			NSArray *adjustedImages = [self adjustImageArray:[dict objectForKey:@"imageUrls"]];
			js = [NSString stringWithFormat:@"iR.appendImages(%@)",
				  [adjustedImages JSONRepresentation]];
		}
	} else if ([cmd isEqualToString:@"sweaveresults"]) {
		NSNumber *fileid = [dict objectForKey:@"fileId"];
		js = [NSString stringWithFormat:@"iR.appendPdf('%@', %@, '%@')", [self escapeForJS:[dict objectForKey:@"pdfurl"]], fileid,
			  [self escapeForJS:[dict objectForKey:@"filename"]]];
		[self.session.workspace updateFileId:fileid];
	}
	if (js) {
		[self.outputController.webView stringByEvaluatingJavaScriptFromString:js];
		[self.outputController.webView stringByEvaluatingJavaScriptFromString:@"scroll(0,document.body.scrollHeight)"];
	}
}

-(void)performConsoleAction:(NSString*)action
{
	action = [action stringbyRemovingPercentEscapes];
	NSString *cmd = [NSString stringWithFormat:@"iR.appendConsoleText('%@')", action];
	[self.outputController.webView stringByEvaluatingJavaScriptFromString:cmd];	
}

-(void)displayImage:(NSString*)imgPath
{
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
	[self.imageController displayImage:[imgPath lastPathComponent]];
}

-(void)displayFile:(RCFile*)file
{
	self.selectedFile = file;
}

-(void)processBinaryMessage:(NSData*)data
{
	if (nil == _outputQueue) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self initializeAudioOut];
		});
	}
	@synchronized (self) {
		if (nil == self.audioQueue)
			self.audioQueue = [NSMutableArray array];
		[self.audioQueue addObject:data];
	}
	if (!IsQueueRunning(_outputQueue) && self.audioQueue.count > 2) {
		AudioQueueBufferRef buffers[3];
		for (int i=0; i < 3; i++) {
			AudioQueueAllocateBuffer(_outputQueue, 950, &buffers[i]);
			MyOutputCallback((__bridge void*)self, _outputQueue, buffers[i]);
		}
		AudioQueueStart(_outputQueue, NULL);
	}
}

#pragma mark - web output delegate

-(void)executeConsoleCommand:(NSString*)command
{
	[self.session executeScript:command];
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
		RCImage *img = [self.imgCache objectForKey:path];
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
	} else {
		//for now. we may want to handle multiple images at once
		[self displayImage:[url path]];
	}
}

#pragma mark - text view delegate

-(void)textDidChange:(NSNotification*)note
{
	NSRange rng = self.editView.selectedRange;
	[self.editView.textStorage setAttributedString:[[RCMSyntaxHighlighter sharedInstance] syntaxHighlight:self.editView.attributedString]];
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
	[MultiFileImporter acceptTableViewFileDrop:tableView dragInfo:info workspace:self.session.workspace 
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
		if ([__selFile.fileContents isEqualToString:self.editView.string])
			[__selFile setLocalEdits:nil];
		else
			[__selFile setLocalEdits:self.editView.string];
	} else
		self.scratchString = self.editView.string;
	__selFile = selectedFile;
	if ([selectedFile.name hasSuffix:@".pdf"]) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:selectedFile];
	} else {
		NSString *newTxt = self.scratchString;
		if (selectedFile)
			newTxt = selectedFile.currentContents;
		NSAttributedString *astr = [NSAttributedString attributedStringWithString:newTxt attributes:nil];
		astr = [[RCMSyntaxHighlighter sharedInstance] syntaxHighlight:astr];
		[self.editView.textStorage setAttributedString:astr];
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
@synthesize imgCache;
@synthesize imgCachePath;
@synthesize dloadQueue;
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
@synthesize audioQueue;
@end

@implementation SessionView
@end

static void MyAudioPropertyListener(void *inUserData, AudioQueueRef queue, AudioQueuePropertyID property)
{
	UInt32 val=0;
	UInt32 valSize = sizeof(val);
	AudioQueueGetProperty(queue, property, &val, &valSize);
	NSLog(@"is queue running? %d", val);
}

static void MyOutputCallback(void *inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inCompleteAQBuffer)
{
	MacSessionViewController *me = (__bridge MacSessionViewController*)inUserData;
	NSData *data = [me popNextAudioOutPacket];
	if (nil == data)
		return;
	inCompleteAQBuffer->mAudioDataByteSize = data.length;
	[data getBytes:inCompleteAQBuffer->mAudioData length:inCompleteAQBuffer->mAudioDataByteSize];
	AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, 0, NULL);
}

static void MyAudioInputCallback(void *inUserData, AudioQueueRef inQueue, AudioQueueBufferRef inBuffer,
								 const AudioTimeStamp *inStartTIme, UInt32 inNumPackets,
								 const AudioStreamPacketDescription *inPacketDesc)
{
	MacSessionViewController *me = (__bridge MacSessionViewController*)inUserData;
	[me processRecordedData:inBuffer];
	AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, NULL);
}

static Boolean IsQueueRunning(AudioQueueRef queue)
{
	UInt32 val=0;
	UInt32 valSize = sizeof(val);
	AudioQueueGetProperty(queue, kAudioQueueProperty_IsRunning, &val, &valSize);
	return val != 0;
}
