//
//  MCWebOutputController.m
//  MacClient
//
//  Created by Mark Lilback on 10/10/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MCWebOutputController.h"

@interface MCWebOutputController() {
	BOOL __didInit;
}
-(void)loadContent;
@end

@implementation MCWebOutputController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if ((self = [super initWithNibName:@"MCWebOutputController" bundle:nil])) {
	}
	
	return self;
}

-(void)awakeFromNib
{
	if (!__didInit) {
		[self loadContent];
		__didInit=YES;
	}
}

-(void)loadContent
{
	NSURL *pageUrl = [[NSBundle mainBundle] URLForResource:@"console" withExtension:@"html" subdirectory:@"console"];
	if (pageUrl) {
		[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:pageUrl]];
	}
}

#pragma mark - webview delegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//change the background
	NSString *bgColor = @"#fbc1b5";
	if ([bgColor length] > 2) {
		NSString *cmd = [NSString stringWithFormat:@"$('body').css('background-color', '%@')", bgColor];
		[self.webView stringByEvaluatingJavaScriptFromString:cmd];
	}
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Error loading web request:%@", error);
}

-(NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
   defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil; // disable contextual menu for the webView
}

-(void)webView:(WebView *)webView 
decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
	   request:(NSURLRequest *)request frame:(WebFrame *)frame 
decisionListener:(id < WebPolicyDecisionListener >)listener
{
	int navType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
	if (WebNavigationTypeOther == navType) {
		[listener use];
		return;
	} else if (WebNavigationTypeLinkClicked == navType) {
		//it is a url. if it for a fragment on the loaded url, use it
		if ([[request URL] fragment] &&
			[[[request URL] absoluteString] hasPrefix: [webView mainFrameURL]])
		{
			[listener use];
			return;
		} //otherwise, fire off to external browser
		[[NSWorkspace sharedWorkspace] openURL:
		 [actionInformation objectForKey:WebActionOriginalURLKey]];
	}
	[listener ignore];
}


@synthesize webView;
@end
