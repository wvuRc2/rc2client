//
//  MCWebOutputController.m
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCWebOutputController.h"
#import "RCSavedSession.h"
#import "RCMConsoleTextField.h"
#import "AppDelegate.h"
#import "RCMAppConstants.h"
#import "RCImageCache.h"
#import "RCFile.h"
#import <Quartz/Quartz.h>
#import "MAKVONotificationCenter.h"
#import "ThemeEngine.h"

@interface MCWebOutputController() {
	NSInteger __cmdHistoryIdx;
	BOOL __didInit;
}
@property (nonatomic, strong) NSMenuItem *clearMenuItem;
@property (nonatomic, strong) NSMenuItem *saveAsMenuItem;
@property (nonatomic, strong) NSMenuItem *openFullMenuItem;
@property (nonatomic, weak) RCFile *currentPdf;
@property (nonatomic, copy) NSString *lastContent;
@property (nonatomic) BOOL ignoreExecuteMessage;
@property (nonatomic, strong) NSPopover *imagePopover;
@property (nonatomic, strong) NSMenuItem *viewSourceMenuItem;
@property (nonatomic, strong) NSMutableArray *commandHistory;
@property (nonatomic, strong) NSMutableArray *outputQueue;
@property BOOL completedInitialLoad;
@property (nonatomic, strong) RCFile *localFileToLoadAfterInitialLoad;
@property (nonatomic, copy) NSString *webTmpFileDirectory;
@property (nonatomic, readwrite) BOOL enabledTextField;
@end

@implementation MCWebOutputController
@synthesize inputText=__inputText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if ((self = [super initWithNibName:@"MCWebOutputController" bundle:nil])) {
		self.commandHistory = [[NSMutableArray alloc] init];
		self.outputQueue = [[NSMutableArray alloc] init];
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
		[[WebPreferences standardPreferences] setUsesPageCache:YES];
		self.view.translatesAutoresizingMaskIntoConstraints = NO;
		[self loadContent];
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
		__didInit=YES;
		__weak MCWebOutputController *bself = self;
		[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
			[self.webView stringByEvaluatingJavaScriptFromString:[self themedStyleSheet]];
		}];
	}
}

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(loadPreviousCommand:) || action == @selector(loadNextCommand:)) {
		return self.consoleField.fieldOrEditorIsFirstResponder && self.commandHistory.count > 0;
	}
	if (action == @selector(viewFullWindow:) && nil != self.currentPdf)
		return YES;
	return NO;
}

#pragma mark - meat & potatos

-(NSString*)themedStyleSheet
{
	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$('#themecss').attr('href','%@?%1f'); forceStyleRefresh();", theme.cssfile, [NSDate timeIntervalSinceReferenceDate]]];

	return [NSString stringWithFormat:@"$(\"<style type='text/css'>#consoleOutputGenerated > table > tbody > tr:nth-child(even) {	background-color: #%@; } "
			"#consoleOutputGenerated > table > tbody > tr:nth-child(odd) {background-color: #%@; } table.ir-mx th {background-color: #%@} "
			"</style>\").appendTo('head')",
			[theme hexStringForKey: @"ResultsEvenRow"], [theme hexStringForKey: @"ResultsOddRow"],
			[theme hexStringForKey: @"ResultsHeader"]];
}

-(void)updateTextFieldStatus
{
	self.enabledTextField = !(self.restrictedMode || self.delegate.restricted);
}

-(void)viewSource:(id)sender
{
	AppDelegate *del = (AppDelegate*)[NSApp delegate];
	[del displayTextInExternalEditor:self.webView.mainFrameDocument.body.innerHTML];
}

-(void)loadContent
{
	NSURL *pageUrl = [[NSBundle mainBundle] URLForResource:@"console" withExtension:@"html" subdirectory:@"console"];
	if (pageUrl) {
		[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:pageUrl]];
	}
}

-(void)insertSavedContent:(NSString*)contentHtml
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"console" withExtension:@"html" subdirectory:@"console"];
	if ([contentHtml length] > 0) {
		NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		content = [content stringByReplacingOccurrencesOfString:@"<!--content-->" withString:contentHtml];
		[[self.webView mainFrame] loadHTMLString:content baseURL:[url URLByDeletingLastPathComponent]];
	} else {
		[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	}
}

-(void)saveSessionState:(RCSavedSession*)savedState
{
	savedState.consoleHtml = [self.webView stringByEvaluatingJavaScriptFromString:@"$('#consoleOutputGenerated').html()"];
	savedState.commandHistory = self.commandHistory;
	NSData *wprefs = [NSKeyedArchiver archivedDataWithRootObject:self.webView.preferences];
	[savedState setProperty:wprefs forKey:@"webPreferences"];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self insertSavedContent:savedState.consoleHtml];
	[self.commandHistory removeAllObjects];
	[self.commandHistory addObjectsFromArray:savedState.commandHistory];
	self.historyHasItems = self.commandHistory.count > 0;
	NSData *wpdata = [savedState propertyForKey:@"webPreferences"];
	if (wpdata)
		self.webView.preferences = [NSKeyedUnarchiver unarchiveObjectWithData:wpdata];
}

-(NSString*)executeJavaScript:(NSString*)js
{
	//if they are viewing a help page or pdf then js execution will fail. So we queue the command to run
	// after we reload the content
	NSString *res = [self.webView stringByEvaluatingJavaScriptFromString:@"iR.graphFileUrl"];
	if (res.length < 4) {
		//queue the action
		if (0 == self.outputQueue.count) {
			//reload our content
			[self loadContent];
		}
		[self.outputQueue addObject:js];
	} else {
		//ok to do it
		return [self.webView stringByEvaluatingJavaScriptFromString:js];
	}
	return @"";
}
/*
-(void)previewImage:(DOMElement*)imgGroupElem images:(WebScriptObject*)images
{
	unsigned int idx=0;
	NSMutableArray *imgArray = [NSMutableArray array];
	NSPoint pt = NSZeroPoint;
	do {
		DOMHTMLAnchorElement *img = [images webScriptValueAtIndex:idx++];
		if (idx == 1)
			pt = NSMakePoint(img.offsetLeft, img.offsetTop);
		if (![img isKindOfClass:[DOMHTMLAnchorElement class]])
			break;
		NSString *path = [img href];
		NSInteger loc = [path indexOf:@"///"];
		if (loc != NSNotFound)
			path = [[path substringFromIndex:loc+2] lastPathComponent];
		[imgArray addObject:path];
	} while (YES);
	[self.delegate previewImages:imgArray atPoint:pt];
}
*/
-(void)closePreview:(DOMElement*)anchorElem
{
	[self.delegate previewImages:nil atPoint:NSZeroPoint];
}

-(void)loadFileUrl:(NSURL*)url
{
	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

// adds ".txt" on to the end and copies to a tmp directory that will be cleaned up later
-(void)loadFileFromWebTmp:(RCFile*)file
{
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (nil == self.webTmpFileDirectory) {
		self.webTmpFileDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
		[fm createDirectoryAtPath:self.webTmpFileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *newPath = [self.webTmpFileDirectory stringByAppendingPathComponent:file.name];
	if (NSOrderedSame != [file.name.pathExtension caseInsensitiveCompare:@"html"])
		newPath = [newPath stringByAppendingPathExtension:@"txt"];
	__block NSError *err=nil;
	if ([fm fileExistsAtPath:newPath])
		[fm removeItemAtPath:newPath error:nil];
	if (file.contentsLoaded) {
		if (![fm fileExistsAtPath:file.fileContentsPath]) {
			if (![file.currentContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
				Rc2LogError(@"failed to write web tmp file:%@", err);
		} else if (![fm copyItemAtPath:file.fileContentsPath toPath:newPath error:&err]) {
			Rc2LogError(@"error copying file:%@", err);
		}
		[self loadFileUrl:[NSURL fileURLWithPath:newPath]];
	} else {
		[file updateContentsFromServer:^(NSInteger success){
			if (success) {
				if ([file.currentContents writeToFile:newPath atomically:NO encoding:NSUTF8StringEncoding error:&err])
					[self loadFileUrl:[NSURL fileURLWithPath:newPath]];
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
	if (!self.completedInitialLoad) {
		self.localFileToLoadAfterInitialLoad = file;
		return;
	}
	if (self.webView.isLoading) {
		RunAfterDelay(0.3, ^{
			[self loadLocalFile:file];
		});
		return;
	}
	NSString *filePath = file.fileContentsPath;
	if ([file.name hasSuffix:@".pdf"]) {
		self.currentPdf = file;
		[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
	} else
		[self loadFileFromWebTmp:file];
}

#pragma mark - actions

-(IBAction)doExecuteQuery:(id)sender
{
	if (!self.ignoreExecuteMessage) {
		[self.consoleField.window endEditing];
		[self.delegate executeConsoleCommand:self.inputText];
		[self addToCommandHistory:self.inputText];
	}
}

-(IBAction)executeQueryViaButton:(id)sender
{
	self.ignoreExecuteMessage=YES;
	[self.consoleField.window endEditing];
	self.ignoreExecuteMessage=NO;
	[self.delegate executeConsoleCommand:self.inputText];
	[self addToCommandHistory:self.inputText];
}

-(IBAction)doClear:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.clearConsole()"];
	[[RCImageCache sharedInstance] clearCache];
}

-(IBAction)saveSelectedPDF:(id)sender
{
	
}

-(IBAction)openInWebBrowser:(id)sender
{
	NSURL *url = self.webView.mainFrame.dataSource.request.URL;
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(IBAction)goBack:(id)sender
{
	if (!self.webView.canGoBack) {
		//somehow our content got lost. we need to reload it
		[self.webView setMaintainsBackForwardList:NO];
		[self loadContent];
		return;
	}
	[self.webView goBack:sender];
	self.currentPdf = nil;
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
	self.inputText = mi.title;
	self.canExecute = self.inputText.length > 0;
	[self.consoleField.window makeFirstResponder:self.consoleField];
}

-(IBAction)viewFullWindow:(id)sender
{
	if (self.currentPdf) {
		[(AppDelegate*)[NSApp delegate] displayPdfFile:self.currentPdf];
	}
//	NSURL *pdfUrl = self.webView.mainFrame.dataSource.request.URL;
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

#pragma mark - webscripting support

+(NSString*)webScriptNameForSelector:(SEL)sel
{
//	if (sel == @selector(previewImage:images:))
//		return @"preview";
	if (sel == @selector(closePreview:))
		return @"closePreview";
	return nil;
}

+(BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
//	if (sel == @selector(previewImage:images:))
//		return NO;
	if (sel == @selector(closePreview:))
		return NO;
	return YES;
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
	BOOL isOurContent = [[[[frame DOMDocument] documentElement] getAttribute:@"rc2"] isEqualToString:@"rc2"];
	self.consoleVisible = isOurContent;
	if (self.lastContent && isOurContent) {
		DOMHTMLElement *doc = (DOMHTMLElement*)[[frame DOMDocument] documentElement];
		if (doc.innerText.length < 1) {
			doc.innerHTML = self.lastContent;
			self.lastContent=nil;
		}
		if (self.outputQueue.count > 0) {
			for (NSString *js in self.outputQueue)
				[self.webView stringByEvaluatingJavaScriptFromString:js];
			[self.outputQueue removeAllObjects];
		}
	}
	if (isOurContent) {
		NSString *ss = [self themedStyleSheet];
		[sender stringByEvaluatingJavaScriptFromString:ss];
	}
	if (nil == self.webView.backForwardList)
		[self.webView setMaintainsBackForwardList:YES];
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
		} else if ([urlStr hasPrefix: @"http://rc2.stat.wvu.edu/"]) {
			[listener use];
			return;
		} else if ([[[request URL] scheme] isEqualToString:@"rc2file"]) {
			NSRect imgRect = [[[actionInformation objectForKey:WebActionElementKey] objectForKey:@"WebElementImageRect"] rectValue];
			[self.delegate displayLinkedFile:request.URL.path atPoint:imgRect.origin];
		} else if ([[[request URL] scheme] isEqualToString:@"rc2img"]) {
			//displaying a pdf
			[self.delegate handleImageRequest:[request URL]];
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
	for (NSMenuItem *mi in defaultMenuItems) {
		if (mi.tag == WebMenuItemTagGoBack || mi.tag == WebMenuItemTagGoForward || [@"Inspect Element" isEqualToString:mi.title])
			[items addObject:mi];
	}
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

#pragma mark - synthesizers

-(void)setDelegate:(id<MCWebOutputDelegate>)delegate
{
	_delegate = delegate;
	[self observeTarget:self.delegate keyPath:@"restrictedMode" selector:@selector(updateTextFieldStatus) userInfo:nil options:0];
}

-(void)setInputText:(NSString *)inputText
{
	__inputText = inputText;
	self.canExecute = [inputText length] > 0;
}

@end
