//
//  ConsoleViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import "ConsoleViewController.h"
#import "RCSession.h"
#import "RCSavedSession.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "RCImageCache.h"
#import "MAKVONotificationCenter.h"
#import "VariableListViewController.h"

@interface ConsoleViewController() {
	BOOL _didSetGraphUrl;
}
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) VariableListViewController *variableController;
@property (nonatomic, strong) UIPopoverController *varablePopover;
@property (nonatomic, strong) NSString *lastPageContent;
@property (nonatomic, strong) NSLock *queueLock;
@property (nonatomic, strong) NSMutableArray *jsQueue;
@property (nonatomic, strong) id sessionKvoToken;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property BOOL haveExternalKeyboard;
-(void)sessionModeChanged;
@end

@implementation ConsoleViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_didSetGraphUrl=NO;
	self.webView.delegate = self;
	self.queueLock = [[NSLock alloc] init];
	self.jsQueue = [[NSMutableArray alloc] init];
	self.backButton.enabled = NO;
	[self insertSavedContent:@""];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

-(void)didReceiveMemoryWarning
{
	Rc2LogWarn(@"%@: memory warning", THIS_FILE);
}

-(void)keyboardWillShow:(NSNotification*)note
{
	CGRect endFrame = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
		self.haveExternalKeyboard = endFrame.origin.y != 0;
	else
		self.haveExternalKeyboard = self.textField.inputAccessoryView.frame.size.height == 768 - endFrame.origin.x;
}

#pragma mark - meat & potatos

-(void)insertSavedContent:(NSString*)contentHtml
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"console" withExtension:@"html" subdirectory:@"console"];
	if ([contentHtml length] > 0) {
		NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		content = [content stringByReplacingOccurrencesOfString:@"<!--content-->" withString:contentHtml];
		[self.webView loadHTMLString:content baseURL:[url URLByDeletingLastPathComponent]];
	} else {
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
}

-(void)saveCurrentContent
{
	self.lastPageContent = [self.webView stringByEvaluatingJavaScriptFromString:@"$('#consoleOutputGenerated').html()"];	
}

-(BOOL)currentPageIsConsole
{
	NSString *path = self.webView.request.URL.path.lastPathComponent;
	return [path isEqualToString:@"console"] || [path isEqualToString:@"console.html"];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	[self insertSavedContent:savedState.consoleHtml];
}

-(void)sessionModeChanged
{
	[self adjustInterface];
}

-(NSString*)evaluateJavaScript:(NSString*)script
{
	if (![self currentPageIsConsole]) {
		if (self.lastPageContent) {
			[self insertSavedContent:self.lastPageContent];
			self.lastPageContent=nil;
			//loading will be true so script will get queued
		}
	}
	[self.queueLock lock];
	if (self.webView.loading || self.jsQueue.count > 0) {
		[self.jsQueue addObject:script];
		[self.queueLock unlock];
		return @"";
	}
	NSString *res = [self.webView stringByEvaluatingJavaScriptFromString:script];
	[self.queueLock unlock];
	return res;
}

-(void)loadHelpURL:(NSURL*)url
{
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)loadLocalFileURL:(NSURL*)url
{
	[self saveCurrentContent];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)executeQueuedJavaScript
{
	[self.queueLock lock];
	if (self.jsQueue.count > 0) {
		NSString *js = self.jsQueue.firstObject;
		[self.jsQueue removeObjectAtIndex:0];
		[self.webView stringByEvaluatingJavaScriptFromString:js];
		if (self.jsQueue.count > 0) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self executeQueuedJavaScript];
			});
		}
	}
	[self.queueLock unlock];
}

-(void)adjustInterface
{
	BOOL restricted = self.session.restrictedMode;
	[self.textField setEnabled:!restricted];
	self.executeButton.enabled = !restricted;
	self.actionButton.enabled = !restricted;
	if (restricted)
		self.backButton.enabled = NO;
	else {
		NSString *scheme = self.webView.request.URL.scheme;
		self.backButton.enabled = [scheme hasPrefix:@"http"] || ([scheme hasPrefix:@"file"] && ![self currentPageIsConsole]);	
	}
}

-(void)variablesUpdated
{
	[self.variableController variablesUpdated];
}

#pragma mark - actions

-(IBAction)doShowVariables:(id)sender
{
	if (nil == self.varablePopover) {
		self.variableController = [[VariableListViewController alloc] init];
		self.variableController.session = self.session;
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.variableController];
		self.varablePopover = [[UIPopoverController alloc] initWithContentViewController:nav];
		self.varablePopover.delegate = self.variableController;
	}
	if (self.actionSheet.isVisible) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
		self.actionSheet=nil;
	}
	if (self.varablePopover.isPopoverVisible) {
		[self.varablePopover dismissPopoverAnimated:YES];
	} else {
		[self.varablePopover presentPopoverFromBarButtonItem:sender
									permittedArrowDirections:UIPopoverArrowDirectionUp|UIPopoverArrowDirectionAny
													animated:YES];
	}
}

-(IBAction)doExecute:(id)sender
{
	if (!self.haveExternalKeyboard)
		[self.textField resignFirstResponder];
	[_session executeScript:self.textField.text scriptName:nil];
}

-(IBAction)doDecreaseFont:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.decreaseFontSize()"];
}

-(IBAction)doIncreaseFont:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.increaseFontSize()"];
}

-(IBAction)doActionSheet:(id)sender
{
	if (self.actionSheet.isVisible) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
		self.actionSheet=nil;
		return;
	}
	if (self.varablePopover.isPopoverVisible)
		[self.varablePopover dismissPopoverAnimated:YES];
	NSArray *actionItems = @[
								 [AMActionItem actionItemWithName:@"Clear" target:self action:@selector(doClear:) userInfo:nil],
								 [AMActionItem actionItemWithName:@"Decrease Font Size" target:self action:@selector(doDecreaseFont:) userInfo:nil],
								 [AMActionItem actionItemWithName:@"Increase Font Size" target:self action:@selector(doIncreaseFont:) userInfo:nil]
	];
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil actionItems:actionItems];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

-(IBAction)doClear:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.clearConsole()"];
	[[RCImageCache sharedInstance] clearCache];
	self.lastPageContent=@"";
}

-(IBAction)doBack:(id)sender
{
	if (self.webView.canGoBack)
		[self.webView goBack];
	else if (self.lastPageContent) {
		[self insertSavedContent:self.lastPageContent];
		self.lastPageContent=nil;
	} else {
		[self insertSavedContent:@""];
	}
}

-(NSString*)themedStyleSheet
{
	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	return [NSString stringWithFormat:@"$(\"<style type='text/css'>#consoleOutputGenerated > table > tbody > tr:nth-child(even) {	background-color: #%@; } "
			"#consoleOutputGenerated > table > tbody > tr:nth-child(odd) {background-color: #%@; } table.ir-mx th {background-color: #%@} "
			"</style>\").appendTo('head')",
			[theme hexStringForKey: @"ResultsEvenRow"], [theme hexStringForKey: @"ResultsOddRow"],
			[theme hexStringForKey: @"ResultsHeader"]];
}

#pragma mark - textfield delegate

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSInteger cnt = aTextField.text.length - range.length + string.length;
	self.executeButton.enabled = cnt > 0;
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
	if (!self.haveExternalKeyboard)
		[self.textField resignFirstResponder];
	[self doExecute:aTextField];
	return NO;
}

#pragma mark - webview delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if (!_didSetGraphUrl) {
		NSURL *theUrl = [[NSBundle mainBundle] URLForResource:@"graph" withExtension:@"png" subdirectory:@"console"];
		NSString *url = [theUrl absoluteString];
		url = [url stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
		_didSetGraphUrl=YES;
		CGRect f = self.webView.frame;
		if (f.origin.x < 10)
			f.origin.x = 10;
		if (f.size.width > self.view.frame.size.width)
			f.size.width = self.view.frame.size.width - 20;
		self.webView.frame = f;
		//change the background
		NSString *bgColor = [[ThemeEngine sharedInstance].currentTheme hexStringForKey:@"ResultsBackground"];
		if ([bgColor length] > 2) {
			NSString *cmd = [NSString stringWithFormat:@"$('body').css('background-color', '#%@')", bgColor];
			[self.webView stringByEvaluatingJavaScriptFromString:cmd];
		}
		NSString *ss = [self themedStyleSheet];
		[self.webView stringByEvaluatingJavaScriptFromString:ss];
	}
	[self.queueLock lock];
	if ([self.jsQueue count] > 0) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self executeQueuedJavaScript];
		});
	}
	[self.queueLock unlock];
	[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"$('#themecss').attr('href','%@')",
														  [[ThemeEngine sharedInstance] currentTheme].cssfile]];
	self.webView.scalesPageToFit = NSOrderedSame == [self.webView.request.URL.pathExtension caseInsensitiveCompare:@"pdf"];
	[self adjustInterface];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
	navigationType:(UIWebViewNavigationType)navigationType
{
	if ([request.URL isFileURL])
		return YES;
	if ([[request.URL scheme] isEqualToString:@"rc2"])
		[self.session.delegate performConsoleAction:[[request.URL absoluteString] substringFromIndex:6]];
	else if ([[[request URL] scheme] isEqualToString:@"rc2img"]) {
		NSString *urlStr = request.URL.absoluteString;
		NSString *path = [request.URL path];
		if ([urlStr hasSuffix:@".pdf"]) {
			path = request.URL.absoluteString;
			path = [path substringFromIndex:[path lastIndexOf:@"/"]+1];
		} else if (![urlStr.pathExtension isEqualToString:@"png"]) {
			path = urlStr.lastPathComponent;
			self.lastPageContent = [self.webView stringByEvaluatingJavaScriptFromString:@"$('#consoleOutputGenerated').html()"];
		}
		[self.session.delegate displayImage:path];
	} else if ([[[request URL] scheme] isEqualToString:@"rc2file"]) {
		[self.session.delegate displayLinkedFile:request.URL.path];
	} else if ([[[request URL] absoluteString] hasPrefix:@"http://rc2.stat.wvu.edu/"]) { //used to have help, no reason to not allow
		[self saveCurrentContent];
		return YES;
	} else if ([[[request URL] absoluteString] hasPrefix:@"http://www.stat.wvu.edu/"]) { //for help pages
		[self saveCurrentContent];
		return YES;
	}
	return NO;
}

#pragma accessors

-(void)setSession:(RCSession*)sess
{
	self.sessionKvoToken = nil;
	_session = sess;
	self.sessionKvoToken = [self observeTarget:sess keyPath:@"restrictedMode" options:0 block:^(MAKVONotification *note) {
		[[note observer] sessionModeChanged];
	}];
}

@end

@implementation ConsoleView

@end