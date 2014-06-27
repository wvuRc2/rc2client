//
//  MCWebOutputController.m
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "MCWebOutputController.h"
#import "RCSavedSession.h"
#import "RCMConsoleTextField.h"
#import "MCMainWindowController.h"
#import "MCAppConstants.h"
#import "RCImageCache.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCImage.h"
#import "RCSession.h"
#import "RCWorkspace.h"
#import "MAKVONotificationCenter.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "MCHelpSheetController.h"

const NSInteger kMinFontSize = 9;
const NSInteger kMaxFontSize = 32;

@interface MCWebOutputController() <NSTextViewDelegate> {
	NSInteger __cmdHistoryIdx;
	BOOL __didInit;
}
@property (nonatomic, weak) IBOutlet NSView *containerView;
@property (nonatomic, strong) IBOutlet NSTextView *textView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *textLeftConstraint;
@property (nonatomic, strong) IBOutlet WebView *webView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *webLeftConstraint;
@property (nonatomic, strong) NSMenuItem *clearMenuItem;
@property (nonatomic, strong) NSMenuItem *saveAsMenuItem;
@property (nonatomic, strong) NSMenuItem *openFullMenuItem;
@property (nonatomic, weak) RCFile *currentFile;
@property (nonatomic, copy) NSString *lastContent;
@property (nonatomic) BOOL ignoreExecuteMessage;
@property (nonatomic, strong) NSPopover *imagePopover;
@property (nonatomic, strong) NSMenuItem *viewSourceMenuItem;
@property (nonatomic, strong) NSMutableArray *commandHistory;
@property (nonatomic, strong) NSFont *outputFont;
@property (nonatomic, strong) MCHelpSheetController *helpSheet;
@property BOOL completedInitialLoad;
@property (nonatomic, strong) RCFile *localFileToLoadAfterInitialLoad;
@property (nonatomic, copy) NSString *webTmpFileDirectory;
@property (nonatomic, readwrite) BOOL enabledTextField;
@end

@implementation MCWebOutputController

- (id)init
{
	if ((self = [super initWithNibName:@"MCWebOutputController" bundle:nil])) {
		self.commandHistory = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void)dealloc
{
	if (self.webTmpFileDirectory) {
		[[NSFileManager defaultManager] removeItemAtPath:self.webTmpFileDirectory error:nil];
		self.webTmpFileDirectory=nil;
	}
}

-(void)awakeFromNib
{
	if (!__didInit) {
		__weak MCWebOutputController *bself = self;
		[[WebPreferences standardPreferences] setUsesPageCache:YES];
		self.view.translatesAutoresizingMaskIntoConstraints = NO;
		self.clearMenuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Output" action:@selector(doClear:) keyEquivalent:@""];
		self.saveAsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Save As…" action:@selector(saveSelectedPDF:) keyEquivalent:@""];
		self.viewSourceMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Source" action:@selector(viewSource:) keyEquivalent:@""];
		self.openFullMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Full Window" action:@selector(viewFullWindow:) keyEquivalent:@""];
		self.consoleVisible = YES;
		self.historyPopUp.preferredEdge = NSMinYEdge;
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(adjustCommandHistoryMenu:) 
													 name:NSPopUpButtonWillPopUpNotification 
												   object:self.historyPopUp];
		[self observeTarget:self keyPath:@"restrictedMode" selector:@selector(updateTextFieldStatus) userInfo:nil options:0];
		[[NSNotificationCenter defaultCenter] addObserverForName:FileDeletedNotification object:nil
														   queue:nil usingBlock:^(NSNotification *note)
		{
			[bself handleFileDeletion:note.object];
		}];
		__didInit=YES;
	}
}

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(loadPreviousCommand:) || action == @selector(loadNextCommand:)) {
		return self.consoleField.fieldOrEditorIsFirstResponder && self.commandHistory.count > 0;
	}
	if (action == @selector(doConsoleBack:)) {
		if (self.restrictedMode) return NO;
		if (self.textLeftConstraint.constant >= 0) return NO;
		return YES;
	}
	if (action == @selector(viewFullWindow:) && [self.currentFile.name hasSuffix:@".pdf"])
		return YES;
	return NO;
}

#pragma mark - meat & potatos

-(void)connectionOpened
{
	[self.textView scrollRangeToVisible:NSMakeRange(self.textView.textStorage.length-2, 1)];
}

-(void)appendAttributedString:(NSAttributedString*)aString
{
	NSMutableAttributedString *attrStr = [aString mutableCopy];
	[attrStr addAttribute:@"NSFont" value:self.outputFont range:NSMakeRange(0, aString.length)];
	NSTextStorage *ts = self.textView.textStorage;
	[ts appendAttributedString:attrStr];
	[self.textView scrollToEndOfDocument:nil];
	[self animateToTextView]; //ony does if not visible
}

-(void)updateTextFieldStatus
{
	self.enabledTextField = !(self.restrictedMode || self.delegate.restricted);
}

-(void)viewSource:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MCEditTextDocumentNotification object:self.webView.mainFrameDocument.body.innerHTML userInfo:nil];
}

-(void)saveSessionState:(RCSavedSession*)savedState
{
	NSError *err;
	NSTextStorage *text = self.textView.textStorage;
	if (text.length > 0) {
		NSData *data = [text RTFDFromRange:NSMakeRange(0, text.length) documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType}];
		if (data)
			savedState.consoleRtf = data;
		else
			Rc2LogError(@"error saving document data:%@", err);
	} else {
		savedState.consoleRtf = nil;
	}
	savedState.commandHistory = self.commandHistory;
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	NSData *rtfdata = savedState.consoleRtf;
	NSError *err;
	if (rtfdata && ![self.textView.textStorage readFromData:rtfdata options:nil documentAttributes:nil error:nil])
		Rc2LogError(@"error reading consolertf:%@", err);
	[self.commandHistory removeAllObjects];
	[self.commandHistory addObjectsFromArray:savedState.commandHistory];
	self.historyHasItems = self.commandHistory.count > 0;
	[self applyFontSize];
	[self.textView.textStorage enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0,self.textView.textStorage.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		NSFileWrapper *fw = [value fileWrapper];
		if ([fw.filename hasPrefix:@"image"]) {
			NSTextAttachmentCell *cell = [[NSTextAttachmentCell alloc] initImageCell:[NSImage imageNamed:@"graph"]];
			[value setAttachmentCell:cell];
		} else if ([fw.filename hasPrefix:@"file"]) {
			[value setAttachmentCell:[self attachmentCellForAttachment:value]];
		}
	}];
}

-(void)applyFontSize
{
	NSInteger fntSize = [[NSUserDefaults standardUserDefaults] integerForKey:kPref_ConsoleFontSize];
	if (fntSize < kMinFontSize || fntSize > kMaxFontSize)
		fntSize = 13;
	NSTextStorage *ts = self.textView.textStorage;
	NSRange rng = NSMakeRange(0, ts.length);
	NSFont *fnt = [NSFont userFixedPitchFontOfSize:fntSize];
	self.outputFont = fnt;
	//was using NSFontName/SizeAttribute, but there was an NSFont value with helvetica 12 that took precedent.
	[ts addAttribute:@"NSFont" value:fnt range:rng];
}

-(NSTextAttachmentCell*)attachmentCellForAttachment:(NSTextAttachment*)tattach
{
	NSDictionary *fdict = [NSKeyedUnarchiver unarchiveObjectWithData:tattach.fileWrapper.regularFileContents];
	Rc2FileType *ftype = [Rc2FileType fileTypeWithExtension:fdict[@"ext"]];
	NSString *imgName = ftype.iconName;
	if (nil == imgName)
		imgName = @"gendoc";
	//for types that don't have a 32x32 image, the 128x was being used. this will force them down.
	NSImage *img = [NSImage imageNamed:imgName];
	[img setSize:NSMakeSize(32, 32)];
	return [[NSTextAttachmentCell alloc] initImageCell:img];
}

-(void)loadFileUrl:(NSURL*)url file:(RCFile*)file
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:file.fileContentsPath]) {
		//need to load the data
		[file updateContentsFromServer:^(NSInteger success) {
			if (success)
				[self loadFileUrl:url file:file];
		}];
		return;
	}
	self.currentFile = file;
	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
	[self animateToWebView];
}

// adds ".txt" on to the end and copies to a tmp directory that will be cleaned up later
-(void)loadFileFromWebTmp:(RCFile*)file
{
	__block NSError *err=nil;
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (nil == self.webTmpFileDirectory || ![fm fileExistsAtPath:self.webTmpFileDirectory]) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		if (![fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:&err]) {
			Rc2LogError(@"failed to create web tmp dir %@: %@", self.webTmpFileDirectory, err);
			return;
		}
	}
	NSString *newPath = [self.webTmpFileDirectory stringByAppendingPathComponent:file.name];
	if (NSOrderedSame != [file.name.pathExtension caseInsensitiveCompare:@"html"])
		newPath = [newPath stringByAppendingPathExtension:@"txt"];
	if ([fm fileExistsAtPath:newPath])
		[fm removeItemAtPath:newPath error:nil];
	if (file.contentsLoaded) {
		if (![fm fileExistsAtPath:file.fileContentsPath]) {
			if (![file.currentContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
				Rc2LogError(@"failed to write web tmp file:%@", err);
		} else if (![fm copyItemAtPath:file.fileContentsPath toPath:newPath error:&err]) {
			Rc2LogError(@"error copying file:%@", err);
		}
		[self loadFileUrl:[NSURL fileURLWithPath:newPath] file:file];
	} else {
		[file updateContentsFromServer:^(NSInteger success){
			if (success) {
				if ([file.currentContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
					[self loadFileUrl:[NSURL fileURLWithPath:newPath] file:file];
				else
					Rc2LogError(@"failed to write web tmp file:%@", err);
				
			} else {
				Rc2LogWarn(@"failed to load file from server");
			}
		}];
	}
}

-(void)loadLocalFile:(RCFile*)file
{
	if (self.webView.isLoading) {
		RunAfterDelay(0.3, ^{
			[self loadLocalFile:file];
		});
		return;
	}
	NSString *filePath = file.fileContentsPath;
	if ([file.name hasSuffix:@".pdf"]) {
		[self loadFileUrl:[NSURL fileURLWithPath:filePath] file:file];
	} else
		[self loadFileFromWebTmp:file];
}

-(void)loadHelpItems:(NSArray*)items topic:(NSString*)helpTopic
{
	self.currentFile = nil;
	if (items.count > 1) {
		MCHelpSheetController *ctrl = [[MCHelpSheetController alloc] init];
		self.helpSheet = ctrl;
		ctrl.helpItems = items;
		ctrl.handler = ^(MCHelpSheetController *bCtrl, NSDictionary *selItem) {
			[NSApp endSheet:bCtrl.window];
			if (selItem)
				[self displayHelp:selItem topic:helpTopic];
			RunAfterDelay(0.5, ^{
				self.helpSheet = nil;
			});
		};
		[NSApp beginSheet:ctrl.window modalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	} else {
		[self displayHelp:items.firstObject topic:helpTopic];
	}
}

-(void)displayHelp:(NSDictionary*)item topic:(NSString*)helpTopic
{
	NSURL *url = item[kHelpItemURL];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
	{
		if ([(NSHTTPURLResponse*)response statusCode] > 399) {
			[self appendAttributedString:[self.delegate.session noHelpFoundString:helpTopic]];
		} else {
			[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
			[self animateToWebView];
		}
	}];
}

-(NSArray*)imageGroupAtCharIndex:(NSInteger)charIndex
{
	NSString *str = self.textView.textStorage.string;
	NSRange lineRange = [str lineRangeForRange:NSMakeRange(charIndex, 1)];
	NSMutableArray *outArray = [NSMutableArray array];
	for (NSUInteger i=lineRange.location; i < NSMaxRange(lineRange); i++) {
		if ([str characterAtIndex:i] == NSAttachmentCharacter) {
			NSTextAttachment *tattach = [self.textView.textStorage attribute:NSAttachmentAttributeName atIndex:i effectiveRange:nil];
			if ([self.delegate.session.delegate textAttachmentIsImage:tattach])
				[outArray addObject:[self.delegate imageForTextAttachment:tattach]];
		}
	}
	return outArray;
}

-(void)previewImage:(NSTextAttachment*)imgAttachment atIndex:(NSInteger)charIndex
{
	RCImage *image = [self.delegate imageForTextAttachment:imgAttachment];
	if (image) {
		[self.delegate.session.delegate displayImage:image fromGroup:[self imageGroupAtCharIndex:charIndex]];
	} else {
		Rc2LogWarn(@"failed to load image attachment %@ from preview", imgAttachment);
	}
}

-(void)previewFile:(NSTextAttachment*)fileAttachment atIndex:(NSInteger)charIndex
{
	NSDictionary *fdict = [NSKeyedUnarchiver unarchiveObjectWithData:fileAttachment.fileWrapper.regularFileContents];
	RCFile *file = [self.delegate.session.workspace fileWithId:fdict[@"id"]];
	if (file) {
		[self loadLocalFile:file];
		[self animateToWebView];
	} else {
		Rc2LogWarn(@"failed to find file for %@", fdict);
	}
}

-(void)handleFileDeletion:(RCFile*)file
{
	[self animateToTextView];
}

-(void)animateToWebView
{
	if (!self.webView.isHidden)
		return;
	self.webLeftConstraint.constant = NSMaxX(self.textView.frame)+1;
	[self.webView setHidden:NO];
	[NSAnimationContext currentContext].completionHandler = ^{
		[self.textView setHidden:YES];
	};
	[self.webView setMaintainsBackForwardList:YES];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		context.duration = 1.0;
		self.textLeftConstraint.constant = - self.containerView.frame.size.width;
		self.webLeftConstraint.constant = 0;
	} completionHandler:^{
		[self.textView setHidden:YES];
		self.consoleVisible = NO;
		[self.view.window.toolbar validateVisibleItems];
	}];
}

-(void)animateToTextView
{
	if (!self.textView.isHidden)
		return;
	self.webLeftConstraint.constant = - NSMaxX(self.textView.frame);
	[self.textView setHidden:NO];
	[self.webView setMaintainsBackForwardList:NO];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		context.duration = 1.0;
		self.textLeftConstraint.constant = 0;
		self.webLeftConstraint.constant = NSMaxX(self.textView.frame)+1;
	} completionHandler:^{
		[self.webView setHidden:YES];
		[self.webView.mainFrame loadHTMLString:@"" baseURL:nil];
		self.consoleVisible = YES;
		[self.view.window.toolbar validateVisibleItems];
	}];
	self.currentFile=nil;
}

#pragma mark - actions

-(IBAction)doExecuteQuery:(id)sender
{
	if (!self.ignoreExecuteMessage) {
		[self.consoleField.window endEditing];
		[self.delegate executeConsoleCommand:self.inputText];
		[self addToCommandHistory:self.inputText];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.consoleField.window makeFirstResponder:self.consoleField];
		});
	}
}

-(IBAction)executeQueryViaButton:(id)sender
{
	self.ignoreExecuteMessage=YES;
	[self.consoleField.window endEditing];
	self.ignoreExecuteMessage=NO;
	[self.delegate executeConsoleCommand:self.inputText];
	[self addToCommandHistory:self.inputText];
	[self.consoleField.window makeFirstResponder:self.consoleField];
}

-(IBAction)doClear:(id)sender
{
	[self.textView.textStorage deleteCharactersInRange:NSMakeRange(0, self.textView.textStorage.length)];
}

-(IBAction)doIncreaseFontSize:(id)sender
{
	if (self.consoleVisible) {
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		NSInteger fntSize = [defs integerForKey:kPref_ConsoleFontSize];
		fntSize++;
		if (fntSize <= kMaxFontSize) {
			[defs setInteger:fntSize forKey:kPref_ConsoleFontSize];
			[self applyFontSize];
		}
	} else {
		[self.webView makeTextLarger:sender];
	}
}

-(IBAction)doDecreaseFontSize:(id)sender
{
	if (self.consoleVisible) {
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		NSInteger fntSize = [defs integerForKey:kPref_ConsoleFontSize];
		fntSize--;
		if (fntSize >= kMinFontSize) {
			[defs setInteger:fntSize forKey:kPref_ConsoleFontSize];
			[self applyFontSize];
		}
	} else {
		[self.webView makeTextSmaller:sender];
	}
}

-(IBAction)saveSelectedPDF:(id)sender
{
	
}

-(IBAction)openInWebBrowser:(id)sender
{
	NSURL *url = self.webView.mainFrame.dataSource.request.URL;
	[[NSWorkspace sharedWorkspace] openURL:url];
}

//for some lame reason, a binding is using goBack which I can't find.
-(void)goBack:(id)sender
{
	[self doConsoleBack:sender];
}

-(IBAction)doConsoleBack:(id)sender
{
	ZAssert(self.textLeftConstraint.constant < 0, @"bad situation");
	if (self.webView.canGoBack) {
		[self.webView goBack:sender];
	} else {
		[self animateToTextView];
	}
}

-(IBAction)loadPreviousCommand:(id)sender
{
	++__cmdHistoryIdx;
	if (__cmdHistoryIdx >= self.commandHistory.count)
		__cmdHistoryIdx = 0;
	NSString *cmd = [self.commandHistory objectAtIndexNoExceptions:__cmdHistoryIdx];
	if (cmd) {
		self.inputText = cmd;
		[self.consoleField selectText:self];
	}
	self.canExecute = self.inputText.length > 0;
}

-(IBAction)loadNextCommand:(id)sender
{
	--__cmdHistoryIdx;
	if (__cmdHistoryIdx < 0)
		__cmdHistoryIdx = self.commandHistory.count - 1;
	NSString *cmd = [self.commandHistory objectAtIndexNoExceptions:__cmdHistoryIdx];
	if (cmd) {
		self.inputText = cmd;
		[self.consoleField selectText:self];
	}
	self.canExecute = self.inputText.length > 0;
}

-(IBAction)displayHistoryItem:(id)sender
{
	NSMenuItem *mi = sender;
	self.inputText = mi.representedObject;
	self.canExecute = self.inputText.length > 0;
	[self.consoleField.window makeFirstResponder:self.consoleField];
}

-(IBAction)viewFullWindow:(id)sender
{
	if ([self.currentFile.name hasSuffix:@".pdf"]) {
		[self.view.window.windowController displayPdfFile:self.currentFile];
	}
//	NSURL *pdfUrl = self.webView.mainFrame.dataSource.request.URL;
}

#pragma mark - text view

-(NSURL*)textView:(NSTextView *)textView URLForContentsOfTextAttachment:(NSTextAttachment *)textAttachment atIndex:(NSUInteger)charIndex
{
	NSFileWrapper *fw = textAttachment.fileWrapper;
	if ([fw.filename hasPrefix:@"file"]) {
		NSDictionary *fdict = [NSKeyedUnarchiver unarchiveObjectWithData:textAttachment.fileWrapper.regularFileContents];
		RCFile *file = [self.delegate.session.workspace fileWithId:fdict[@"id"]];
		return [NSURL fileURLWithPath:file.fileContentsPath];
	} else if ([fw.filename hasPrefix:@"image"]) {
		RCImage *image = [self.delegate imageForTextAttachment:textAttachment];
		return image.fileUrl;
	}
	return nil;
}

-(void)textView:(NSTextView *)view draggedCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)rect event:(NSEvent *)event atIndex:(NSUInteger)charIndex
{
	NSTextAttachment *textAttachment = (NSTextAttachment*)[cell attachment];
	NSFileWrapper *fw = textAttachment.fileWrapper;
	if ([fw.filename hasPrefix:@"file"]) {
		NSDictionary *fdict = [NSKeyedUnarchiver unarchiveObjectWithData:textAttachment.fileWrapper.regularFileContents];
		RCFile *file = [self.delegate.session.workspace fileWithId:fdict[@"id"]];
		if (file) {
			[view dragFile:file.fileContentsPath fromRect:rect slideBack:YES event:event];
		}
	} else if ([fw.filename hasPrefix:@"image"]) {
		RCImage *image = [self.delegate imageForTextAttachment:textAttachment];
		[view dragFile:image.fileUrl.path fromRect:rect slideBack:YES event:event];
	}
}

-(void)textView:(NSTextView *)textView clickedOnCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
	NSTextAttachment *textAttachment = (NSTextAttachment*)[cell attachment];
	NSFileWrapper *fw = textAttachment.fileWrapper;
	if ([fw.filename hasPrefix:@"image"])
		[self previewImage:textAttachment atIndex:charIndex];
	else if ([fw.filename hasPrefix:@"file"])
		[self previewFile:textAttachment atIndex:charIndex];
	else
		Rc2LogWarn(@"unsupported text attachment:%@", fw.filename);
}

#pragma mark - text field

-(BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveToBeginningOfDocument:)) {
		return YES;
	} else if (command == @selector(moveToEndOfDocument:)) {
		return YES;
	} else if (command == @selector(insertNewline:)) {
		[self doExecuteQuery:self];
		[self.consoleField.window makeFirstResponder:self.consoleField];
	}
	return NO;
}

-(void)controlTextDidChange:(NSNotification *)obj
{
	id fieldEditor = [[obj userInfo] objectForKey:@"NSFieldEditor"];
	self.canExecute = [[fieldEditor string] length] > 0;
}

#pragma mark - command history

-(void)adjustCommandHistoryMenu:(NSNotification*)note
{
	NSMenu *menu = self.historyPopUp.menu;
	[menu removeAllItems];
	[menu addItemWithTitle:@"" action:nil keyEquivalent:@""]; //for icon it would show if visible
	for (NSString *item in self.commandHistory) {
		NSString *str = item;
		if (str.length > 50)
			str = [[str substringToIndex:49] stringByAppendingString:@"…"];
		NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:str action:@selector(displayHistoryItem:) keyEquivalent:@""];
		mi.target = self;
		mi.representedObject = item;
		[menu addItem:mi];
	}
}

-(void)addToCommandHistory:(NSString*)command
{
	NSInteger maxLen = [[NSUserDefaults standardUserDefaults] integerForKey:kPref_CommandHistoryMaxLen];
	if (maxLen < 1)
		maxLen = 20;
	else if (maxLen > 99)
		maxLen = 99;
	command = [command stringByTrimmingWhitespace];
	NSUInteger idx = [self.commandHistory indexOfObject:command];
	if (NSNotFound == idx) {
		[self.commandHistory insertObject:command atIndex:0];
		if (self.commandHistory.count > maxLen)
			[self.commandHistory removeLastObject];
	} else {
		//already in there. need to move to end
		[self.commandHistory removeObjectAtIndex:idx];
		[self.commandHistory insertObject:command atIndex:0];
	}
	self.historyHasItems = self.commandHistory.count > 0;
}

#pragma mark - webview delegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//this is only run the first time this method is called.
	//If there was an initial file to load, it couldn't be loaded until our base papge was.
	if (!self.completedInitialLoad) {
		self.completedInitialLoad = YES;
		if (self.localFileToLoadAfterInitialLoad) {
			RCFile *file = self.localFileToLoadAfterInitialLoad; //capture for block
			dispatch_async(dispatch_get_main_queue(), ^{
				[self loadLocalFile:file];
			});
			self.localFileToLoadAfterInitialLoad = nil;
		}
	}
	if ([self.webView.mainFrameURL hasSuffix:@".pdf"]) {
		[self.webView enumerateSubviewsOfClass:[PDFView class] block:^(id aView, BOOL *stop) {
			[aView setDisplayMode:kPDFDisplaySinglePage];
		}];
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)
		return; //don't care of canceled
	Rc2LogWarn(@"Error loading web request:%@", error);
}

-(void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame
{
	DOMHTMLElement *doc = (DOMHTMLElement*)[[frame DOMDocument] documentElement];
	if ([[[[frame DOMDocument] documentElement] getAttribute:@"rc2"] isEqualToString:@"rc2"]) {
		self.lastContent = [doc innerHTML];
	}
}

-(void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[windowObject setValue:self	forKey:@"Rc2"];
}

-(void)webView:(WebView *)aWebView 
decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
	   request:(NSURLRequest *)request frame:(WebFrame *)frame 
decisionListener:(id < WebPolicyDecisionListener >)listener
{
	int navType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	if (WebNavigationTypeOther == navType || WebNavigationTypeBackForward == navType) {
		[listener use];
		return;
	} else if (WebNavigationTypeLinkClicked == navType) {
		NSString *urlStr = [[request URL] absoluteString];
		//it is a url. if it for a fragment on the loaded url, use it
		if ([[request URL] fragment] &&
			[urlStr hasPrefix: [aWebView mainFrameURL]])
		{
			[listener use];
			return;
		} else if ([urlStr hasPrefix: @"http://rc2.stat.wvu.edu/"] || [urlStr hasPrefix: @"http://www.stat.wvu.edu/"]) {
			[listener use];
			return;
		} else if ([[[request URL] scheme] isEqualToString:@"rc2file"]) {
			NSRect imgRect = [[[actionInformation objectForKey:WebActionElementKey] objectForKey:@"WebElementImageRect"] rectValue];
			[self.delegate displayLinkedFile:request.URL.path atPoint:imgRect.origin];
		}
		//otherwise, fire off to external browser
		[[NSWorkspace sharedWorkspace] openURL:
		 [actionInformation objectForKey:WebActionOriginalURLKey]];
	}
	[listener ignore];
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
	defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *items = [NSMutableArray arrayWithObject:self.clearMenuItem];
	[items addObject:[self.viewSourceMenuItem copy]];
	BOOL hasBack = NO;
	NSMenuItem *inspectElemItem=nil;
	for (NSMenuItem *mi in defaultMenuItems) {
		if (mi.tag == WebMenuItemTagGoBack || mi.tag == WebMenuItemTagGoForward)
			[items addObject:mi];
		if (mi.tag == WebMenuItemTagGoBack)
			hasBack = YES;
		if ([@"Inspect Element" isEqualToString:mi.title] && [Rc2Server sharedInstance].isAdmin) {
			inspectElemItem = mi;
		}
	}
	if (!hasBack && !self.consoleVisible && !self.restrictedMode) {
		//add a back men item
		NSMenuItem *backItem = [[NSMenuItem alloc] initWithTitle:@"Back" action:@selector(doConsoleBack:) keyEquivalent:@""];
		[items addObject:backItem];
	}
	[items reverse];
	if (inspectElemItem)
		[items addObject:inspectElemItem];
	//see if a pdf
	NSString *filepath = [[[(WebDataSource*)[[element objectForKey:@"WebElementFrame"] dataSource] request] URL] path];
	if (NSOrderedSame == [filepath.pathExtension caseInsensitiveCompare:@"pdf"]) {
		[items addObject:[self.openFullMenuItem copy]];
		return items;
	}
	//check for html element
	DOMNode *node = [element objectForKey:@"WebElementDOMNode"];
	if (![node isKindOfClass:[DOMHTMLElement class]])
		return items;
	DOMHTMLElement *htmlElem = (DOMHTMLElement*)node;
	if ([htmlElem isKindOfClass:[DOMHTMLImageElement class]]) {
		DOMHTMLImageElement *imgElem = (DOMHTMLImageElement*)htmlElem;
		if ([imgElem.src hasSuffix:@"pdf.png"]) {
			//they are right-clicking on a pdf icon
			[items addObject:[NSMenuItem separatorItem]];
			NSMenuItem *mi = [self.saveAsMenuItem copy];
			mi.representedObject = [(DOMHTMLAnchorElement*)imgElem.parentElement href];
			[items addObject:mi];
		}
	}
	return items;
}

#pragma mark - accessors

-(void)setDelegate:(id<MCWebOutputDelegate>)delegate
{
	_delegate = delegate;
	[self observeTarget:self.delegate keyPath:@"restrictedMode" selector:@selector(updateTextFieldStatus) userInfo:nil options:0];
}

-(void)setInputText:(NSString *)inputText
{
	_inputText = inputText;
	self.canExecute = [inputText length] > 0;
}

-(BOOL)canIncreaseFontSize
{
	if (self.consoleVisible)
		return [[NSUserDefaults standardUserDefaults] integerForKey:kPref_ConsoleFontSize] < kMaxFontSize;
	else
		return self.webView.canMakeTextLarger;
}

-(BOOL)canDecreaseFontSize
{
	if (self.consoleVisible)
		return [[NSUserDefaults standardUserDefaults] integerForKey:kPref_ConsoleFontSize] > kMinFontSize;
	else
		return self.webView.canMakeTextSmaller;
}

@end

