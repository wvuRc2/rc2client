//
//  BottomViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/5/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "BottomViewController.h"
#import "AppConstants.h"
#import "Rc2Server.h"
#import "RCSession.h"

@interface BottomViewController() {
	BOOL _isInited;
}
@end

@implementation BottomViewController

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
	if (!_isInited) {
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"chat" withExtension:@"html" subdirectory:@"console"];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
		__weak BottomViewController *blockSelf = self;
		[[NSNotificationCenter defaultCenter] addObserverForName:kChatMessageNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
				NSString *str = [NSString stringWithFormat:@"insertChat('%@', '%@')",
								 [note.userInfo objectForKey:@"user"],
								 [[note.userInfo objectForKey:@"message"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]
								 ];
				[blockSelf.webView stringByEvaluatingJavaScriptFromString:str];
		}];
		_isInited=YES;
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	[self removeAllBlockObservers];
	_isInited=NO;
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return YES;
}

-(void)sendChatMessage
{
	Rc2Server *server = [Rc2Server sharedInstance];
	[server.currentSession sendChatMessage:self.textField.text];
}

-(BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
	[self sendChatMessage];
	[aTextField resignFirstResponder];
	aTextField.text=@"";
	return NO;
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
navigationType:(UIWebViewNavigationType)navigationType
{
	if ([request.URL isFileURL])
		return YES;
	return NO;
}

@synthesize webView;
@synthesize textField;
@end
