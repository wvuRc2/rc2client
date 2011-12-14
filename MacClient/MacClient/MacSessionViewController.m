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
#import "RCMPDFViewController.h"
#import "Rc2Server.h"
#import "RCMacToolbarItem.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "RCImage.h"
#import "RCSavedSession.h"
#import "RCMTextView.h"
#import "MCNewFileController.h"
#import "RCMAppConstants.h"
#import <Vyana/AMWindow.h>
#import "ASIHTTPRequest.h"
#import "AppDelegate.h"

@interface MacSessionViewController() {
	CGFloat __fileListWidth;
	NSPoint __curImgPoint;
	BOOL __didInit;
	BOOL __movingFileList;
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
@property (nonatomic, strong) NSNumber *fileIdJustImported;
@property (nonatomic, strong) id fullscreenToken;
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
@end

@implementation MacSessionViewController
@synthesize session=__session;
@synthesize selectedFile=__selFile;

-(id)initWithSession:(RCSession*)aSession
{
	self = [super initWithNibName:@"MacSessionViewController" bundle:nil];
	if (self) {
		NSError *err=nil;
		self.session = aSession;
		self.session.delegate = self;
		self.scratchString=@"";
		self.jsQuiteRExp = [NSRegularExpression regularExpressionWithPattern:@"'" options:0 error:&err];
		ZAssert(nil == err, @"error compiling regex, %@", [err localizedDescription]);
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
		NSError *err=nil;
		self.outputController = [[MCWebOutputController alloc] init];
		NSView *croot = [self.contentSplitView.subviews objectAtIndex:1];
		[croot addSubview:self.outputController.view];
		self.outputController.view.frame = croot.bounds;
		self.outputController.delegate = (id)self;
		self.busy = YES;
		self.statusMessage = @"Connecting to server…";
		[self prepareForSession];
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
		[self storeNotificationToken:[[NSNotificationCenter defaultCenter] addObserverForName:RCWorkspaceFilesFetchedNotification 
														  object:nil queue:nil usingBlock:^(NSNotification *note)
		{
			[self.fileTableView reloadData];
			if (self.fileIdJustImported) {
				NSUInteger idx = [self.session.workspace.files indexOfObjectWithValue:self.fileIdJustImported usingSelector:@selector(fileId)];
				if (NSNotFound != idx) {
					[self.fileTableView amSelectRow:idx byExtendingSelection:NO];
				}
				self.fileIdJustImported=nil;
				[self tableViewSelectionDidChange:nil];
			}
		}]];
		__block __unsafe_unretained MacSessionViewController *blockSelf = self;
		self.fullscreenToken = [[NSApp delegate] addObserverForKeyPath:@"isFullScreen" task:^(id obj, NSDictionary *change)
		{
			if ([obj isFullScreen]) {
				if (!blockSelf.fileListVisible) {
					[blockSelf toggleFileList:blockSelf];
					blockSelf->__toggledFileViewOnFullScreen = YES;
				}
			} else if (blockSelf->__toggledFileViewOnFullScreen && blockSelf.fileListVisible) {
				[blockSelf toggleFileList:blockSelf];
				blockSelf->__toggledFileViewOnFullScreen = NO;
			}
		}];
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
	}
}

-(void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (!__didFirstWindow) {
		if ([newWindow isKindOfClass:[AMWindow class]] && 
			[[newWindow valueForKey:@"windowController"] class] == NSClassFromString(@"RCMSessionWindowController"))
		{
			if (self.fileContainerView.frame.origin.x < 0)
				[self toggleFileList:nil];
		} else {
			if (self.fileContainerView.frame.origin.x >= 0)
				[self toggleFileList:nil];
		}
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
	} else if (action == @selector(importFile:) || action == @selector(createNewFile:)) {
		return self.session.hasWritePerm;
	}
	return NO;
}

-(BOOL)fileListVisible
{
	return self.fileContainerView.frame.origin.x >= 0;
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
	//is the current file R or Rnw?
	if ([self.selectedFile.name hasSuffix:@".Rnw"]) {
		[self.session executeSweave:self.selectedFile.name script:self.editView.string];
	} else {
		[self.session executeScript:self.editView.string];
	}
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

-(IBAction)makeBusy:(id)sender
{
	self.busy = ! self.busy;
	self.statusMessage = @"hoo boy";
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

#pragma mark - meat & potatos

-(void)saveSessionState
{
	RCSavedSession *savedState = self.session.savedSessionState;
	savedState.consoleHtml = [self.outputController.webView stringByEvaluatingJavaScriptFromString:@"$('#consoleOutputGenerated').html()"];
	savedState.currentFile = self.selectedFile;
	if (nil == savedState.currentFile)
		savedState.inputText = self.editView.string;
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self.outputController restoreSessionState:savedState];
	if (savedState.currentFile) {
		self.selectedFile = savedState.currentFile;
	} else if ([savedState.inputText length] > 0) {
		self.editView.string = savedState.inputText;
	}
	[self cacheImagesReferencedInHTML:savedState.consoleHtml];
}

-(void)handleNewFile:(NSString*)fileName
{
	NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
	RCFile *file = [RCFile insertInManagedObjectContext:moc];
	file.name = fileName;
	file.fileContents = @"";
	[[[Rc2Server sharedInstance] currentSession].workspace addFile:file];
	[[Rc2Server sharedInstance] saveFile:file completionHandler:^(BOOL success, RCFile *newFile) {
		if (success) {
			self.fileIdJustImported = newFile.fileId;
			[self.session.workspace refreshFiles];
			[self.fileTableView reloadData];
		} else {
			//FIXME: handle error
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
	} else if ([cmd isEqualToString:@"userList"]) {
		js = [NSString stringWithFormat:@"iR.updateUserList(JSON.parse('%@'))", 
			  [[[dict objectForKey:@"data"] objectForKey:@"users"] JSONRepresentation]];
	} else if ([cmd isEqualToString:@"results"]) {
		if ([dict objectForKey:@"helpPath"]) {
			NSString *helpPath = [dict objectForKey:@"helpPath"];
			NSURL *helpUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://rc2.stat.wvu.edu/Rdocs/%@.html", helpPath]];
			[self.outputController.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:helpUrl]];
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
	self.imagePopover.contentViewController = self.imageController;
	self.imageController.imageArray = self.currentImageGroup;
	self.imageController.workspace = self.session.workspace;
	NSRect r = NSMakeRect(__curImgPoint.x+16, self.outputController.webView.frame.size.height - __curImgPoint.y - 16, 1, 1);
	[self.imagePopover showRelativeToRect:r ofView:self.outputController.webView preferredEdge:NSMaxXEdge];
	[self.imageController displayImage:[imgPath lastPathComponent]];
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
	if ([selectedFile.name hasSuffix:@".pdf"]) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:selectedFile];
	} else {
		NSString *newTxt = self.scratchString;
		if (selectedFile)
			newTxt = selectedFile.currentContents;
		[self.editView setString:newTxt];
	}
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
@end

@implementation SessionView
@end