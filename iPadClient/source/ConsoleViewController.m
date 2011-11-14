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

@interface ConsoleViewController() {
	BOOL _didSetGraphUrl;
}
@end

@implementation ConsoleViewController
@synthesize webView=_webView;
@synthesize session=_session;
@synthesize toolbar;
@synthesize textField;
@synthesize executeButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_didSetGraphUrl=NO;
	self.webView.delegate = self;
/*	UIScrollView* sv = nil;
	for(UIView* v in self.webView.subviews){
		if([v isKindOfClass:[UIScrollView class]]) {
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
*/}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.webView.delegate = nil;
	self.webView=nil;
	self.session=nil;
	self.toolbar=nil;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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


-(void)restoreSessionState:(RCSavedSession*)savedState
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"console" withExtension:@"html" subdirectory:@"console"];
	if ([savedState.consoleHtml length] > 0) {
		NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		content = [content stringByReplacingOccurrencesOfString:@"<!--content-->" withString:savedState.consoleHtml];
		[self.webView loadHTMLString:content baseURL:[url URLByDeletingLastPathComponent]];
	} else {
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
}

#pragma mark - actions

-(IBAction)doExecute:(id)sender
{
	[self.textField resignFirstResponder];
	[[Rc2Server sharedInstance].currentSession executeScript:self.textField.text];
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
	NSArray *actionItems = ARRAY(
								 [AMActionItem actionItemWithName:@"Clear" target:self action:@selector(doClear:) userInfo:nil],
								 [AMActionItem actionItemWithName:@"Decrease Font Size" target:self action:@selector(doDecreaseFont:) userInfo:nil],
								 [AMActionItem actionItemWithName:@"Increase Font Size" target:self action:@selector(doIncreaseFont:) userInfo:nil]
	);
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Console Actions" actionItems:actionItems];
	[sheet showFromBarButtonItem:sender animated:YES];
	[sheet autorelease];
}

-(IBAction)doClear:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.clearConsole()"];
}

-(NSString*)themedStyleSheet
{
	Theme *theme = [ThemeEngine sharedInstance].currentTheme;
	return [NSString stringWithFormat:@"$(\"<style type='text/css'>#consoleOutputGenerated > table > tbody > tr:nth-child(even) {	background-color: %@; } "
			"#consoleOutputGenerated > table > tbody > tr:nth-child(odd) {background-color: %@; } table.ir-mx th {background-color: %@} "
			"</style>\").appendTo('head')",
			[theme consoleValueForKey: @"outputEvenRowColor"], [theme consoleValueForKey: @"outputOddRowColor"],
			[theme consoleValueForKey: @"outputHeaderColor"]];
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
		NSString *cmd = [NSString stringWithFormat:@"iR.graphFileUrl = '%@'", url];
		[self.webView stringByEvaluatingJavaScriptFromString:cmd];
		_didSetGraphUrl=YES;
		CGRect f = self.webView.frame;
		if (f.origin.x < 10)
			f.origin.x = 10;
		if (f.size.width > self.view.frame.size.width)
			f.size.width = self.view.frame.size.width - 20;
		self.webView.frame = f;
		//change the background
		NSString *bgColor = [[ThemeEngine sharedInstance].currentTheme consoleValueForKey:@"background"];
		if ([bgColor length] > 2) {
			NSString *cmd = [NSString stringWithFormat:@"$('body').css('background-color', '%@')", bgColor];
			[self.webView stringByEvaluatingJavaScriptFromString:cmd];
		}
		NSString *ss = [self themedStyleSheet];
		[self.webView stringByEvaluatingJavaScriptFromString:ss];
	}
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
	navigationType:(UIWebViewNavigationType)navigationType
{
	if ([request.URL isFileURL])
		return YES;
	if ([[request.URL scheme] isEqualToString:@"rc2"])
		[self.session.delegate performConsoleAction:[[request.URL absoluteString] substringFromIndex:6]];
	else if ([[[request URL] scheme] isEqualToString:@"rc2img"])
		[self.session.delegate displayImage:[[request URL] path]];
	return NO;
}

@end

@implementation ConsoleView

@end