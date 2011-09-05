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

@interface ConsoleViewController() {
	BOOL _didSetGraphUrl;
	BOOL _didLoadFromNib;
}
@end

@implementation ConsoleViewController
@synthesize webView=_webView;
@synthesize session=_session;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_didSetGraphUrl=NO;
	self.webView.delegate = self;
	if (!_didLoadFromNib) {
		NSLog(@"self=%@, web=%@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.webView.frame));
		CGRect f = self.webView.frame;
//		if (f.origin.x < 10)
//			f.origin.x = 10;
		f.origin.x = 20;
		f.size.width = self.view.frame.size.width - 40;
	//	if (f.size.width > self.view.frame.size.width)
	//		f.size.width = self.view.frame.size.width;
		self.webView.frame = f;
		NSLog(@"self=%@, web=%@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.webView.frame));
		_didLoadFromNib = YES;
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.webView.delegate = nil;
	self.webView=nil;
	self.session=nil;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
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

-(IBAction)doClear:(id)sender
{
	[self.webView stringByEvaluatingJavaScriptFromString:@"iR.clearConsole()"];
}

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
