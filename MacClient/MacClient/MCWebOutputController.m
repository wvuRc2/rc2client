//
//  MCWebOutputController.m
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MCWebOutputController.h"
#import "RCSavedSession.h"
#import "RCMConsoleTextField.h"
#import "AppDelegate.h"
#import "RCMAppConstants.h"

@interface MCWebOutputController() {
	NSInteger __cmdHistoryIdx;
	BOOL __didInit;
}
@property (nonatomic, strong) NSMenuItem *clearMenuItem;
@property (nonatomic, strong) NSMenuItem *saveAsMenuItem;
@property (nonatomic, copy) NSString *lastContent;
@property (nonatomic) BOOL ignoreExecuteMessage;
@property (nonatomic, strong) NSPopover *imagePopover;
@property (nonatomic, strong) NSMenuItem *viewSourceMenuItem;
@property (nonatomic, strong) NSMutableArray *commandHistory;
-(void)loadContent;
-(void)viewSource:(id)sender;
-(void)jserror:(id)err;
-(void)addToCommandHistory:(NSString*)command;
-(void)adjustCommandHistoryMenu:(NSNotification*)note;
@end

@implementation MCWebOutputController
@synthesize inputText=__inputText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if ((self = [super initWithNibName:@"MCWebOutputController" bundle:nil])) {
		self.commandHistory = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void)awakeFromNib
{
	if (!__didInit) {
		[[WebPreferences standardPreferences] setUsesPageCache:YES];
		[self loadContent];
		self.clearMenuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Output" action:@selector(doClear:) keyEquivalent:@""];
		self.saveAsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Save As…" action:@selector(saveSelectedPDF:) keyEquivalent:@""];
		self.viewSourceMenuItem = [[NSMenuItem alloc] initWithTitle:@"View Source" action:@selector(viewSource:) keyEquivalent:@""];
		self.consoleVisible = YES;
		self.historyPopUp.preferredEdge = NSMinYEdge;
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(adjustCommandHistoryMenu:) 
													 name:NSPopUpButtonWillPopUpNotification 
												   object:self.historyPopUp];
		__didInit=YES;
	}
}

-(BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	SEL action = [item action];
	if (action == @selector(loadPreviousCommand:) || action == @selector(loadNextCommand:)) {
		return self.consoleField.fieldOrEditorIsFirstResponder && self.commandHistory.count > 0;
	}
	return NO;
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
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self insertSavedContent:savedState.consoleHtml];
	[self.commandHistory removeAllObjects];
	[self.commandHistory addObjectsFromArray:savedState.commandHistory];
	self.historyHasItems = self.commandHistory.count > 0;
}

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

-(void)closePreview:(DOMElement*)anchorElem
{
	[self.delegate previewImages:nil atPoint:NSZeroPoint];
}

-(void)jserror:(id)err
{
	NSLog(@"err=%@", err);
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
	[self.webView goBack:sender];
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
	if (sel == @selector(previewImage:images:))
		return @"preview";
	else if (sel == @selector(closePreview:))
		return @"closePreview";
	else if (sel == @selector(jserror:))
		return @"handleError";
	return nil;
}

+(BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if (sel == @selector(previewImage:images:))
		return NO;
	else if (sel == @selector(closePreview:))
		return NO;
	else if (sel == @selector(jserror:))
		return NO;
	return YES;
}

#pragma mark - webview delegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	BOOL isOurContent = [[[[frame DOMDocument] documentElement] getAttribute:@"rc2"] isEqualToString:@"rc2"];
	self.consoleVisible = isOurContent;
	if (self.lastContent && isOurContent) {
		DOMHTMLElement *doc = (DOMHTMLElement*)[[frame DOMDocument] documentElement];
		if (doc.innerText.length < 1) {
			doc.innerHTML = self.lastContent;
			self.lastContent=nil;
		}
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Error loading web request:%@", error);
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

-(void)webView:(WebView *)webView 
decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
	   request:(NSURLRequest *)request frame:(WebFrame *)frame 
decisionListener:(id < WebPolicyDecisionListener >)listener
{
	int navType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	if (WebNavigationTypeOther == navType || WebNavigationTypeBackForward == navType) {
		[listener use];
		return;
	} else if (WebNavigationTypeLinkClicked == navType) {
		//it is a url. if it for a fragment on the loaded url, use it
		if ([[request URL] fragment] &&
			[[[request URL] absoluteString] hasPrefix: [webView mainFrameURL]])
		{
			[listener use];
			return;
		} else if ([[[request URL] absoluteString] hasPrefix: @"http://rc2.stat.wvu.edu/"]) {
			[listener use];
			return;
		} else if ([[[request URL] scheme] isEqualToString:@"rc2img"]) {
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
		if (mi.tag == 2024 || mi.tag == WebMenuItemTagGoBack || mi.tag == WebMenuItemTagGoForward)
			[items addObject:mi];
	}
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
			NSLog(@"par = %@", [(DOMHTMLAnchorElement*)imgElem.parentElement href]);
			mi.representedObject = [(DOMHTMLAnchorElement*)imgElem.parentElement href];
			[items addObject:mi];
		}
	}
	return items;
}

#pragma mark - synthesizers

-(void)setInputText:(NSString *)inputText
{
	__inputText = inputText;
	self.canExecute = [inputText length] > 0;
}

@synthesize webView;
@synthesize delegate;
@synthesize imagePopover;
@synthesize consoleField;
@synthesize canExecute;
@synthesize ignoreExecuteMessage;
@synthesize clearMenuItem;
@synthesize saveAsMenuItem;
@synthesize viewSourceMenuItem;
@synthesize lastContent;
@synthesize consoleVisible;
@synthesize commandHistory;
@synthesize historyPopUp;
@synthesize historyHasItems;
@end
