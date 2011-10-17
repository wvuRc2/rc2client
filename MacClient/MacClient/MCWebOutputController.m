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
@property (nonatomic, strong) NSPopover *imagePopover;
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

#pragma mark - webscripting support

+(NSString*)webScriptNameForSelector:(SEL)sel
{
	if (sel == @selector(previewImage:images:))
		return @"preview";
	else if (sel == @selector(closePreview:))
		return @"closePreview";
	return nil;
}

+(BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if (sel == @selector(previewImage:images:))
		return NO;
	else if (sel == @selector(closePreview:))
		return NO;
	return YES;
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
/*
-(NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
   defaultMenuItems:(NSArray *)defaultMenuItems
{
	return nil; // disable contextual menu for the webView
}
*/
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
		} else if ([[[request URL] scheme] isEqualToString:@"rc2img"]) {
			[self.delegate handleImageRequest:[request URL]];
		}
		//otherwise, fire off to external browser
		[[NSWorkspace sharedWorkspace] openURL:
		 [actionInformation objectForKey:WebActionOriginalURLKey]];
	}
	[listener ignore];
}


@synthesize webView;
@synthesize delegate;
@synthesize imagePopover;
@end