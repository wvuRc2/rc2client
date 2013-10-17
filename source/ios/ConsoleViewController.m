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
#import "RCWorkspace.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "RCImageCache.h"
#import "RCImage.h"
#import "RCFile.h"
#import "MAKVONotificationCenter.h"
#import "VariableListViewController.h"
#import "ImagePreviewTransition.h"
#import "ImagePreviewViewController.h"
#import <objc/runtime.h>

#define kAnimDuration 0.5

@interface ConsoleViewController()<UITextViewDelegate,UIViewControllerTransitioningDelegate> {
	BOOL _didSetGraphUrl;
}
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITextView *outputView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) UIView *visibleOutputView;
@property (nonatomic, strong) NSLayoutConstraint *outputLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *webLeftConstraint;
@property (nonatomic, strong) VariableListViewController *variableController;
@property (nonatomic, strong) UIPopoverController *varablePopover;
@property (nonatomic, strong) id sessionKvoToken;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIFont *baseFont;
@property BOOL haveExternalKeyboard;
-(void)sessionModeChanged;
@end

@implementation ConsoleViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	_didSetGraphUrl=NO;
	self.backButton.enabled = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	self.outputView = [[UITextView alloc] initWithFrame:self.containerView.bounds];
	self.outputView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.containerView addSubview:self.outputView];
	self.outputLeftConstraint = [self setupContentSubviewConstraints:self.outputView];
	self.visibleOutputView = self.outputView;
	
	[self setupWebView];
	
	UIFontDescriptor *sysFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
	UIFont *myFont = [UIFont fontWithName:@"Inconsolata" size:sysFont.pointSize];
	self.outputView.font = myFont;
	self.baseFont = myFont;
	//part of a hack to get text attachment tapping to work. see textTapped: for details
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
	tap.numberOfTapsRequired = 1;
	[self.outputView addGestureRecognizer:tap];
}

-(void)setupWebView
{
	self.webView = [[UIWebView alloc] initWithFrame:self.containerView.bounds];
	self.webView.delegate = self;
	self.webView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.containerView addSubview:self.webView];
	self.webLeftConstraint = [self setupContentSubviewConstraints:self.webView];
	self.webLeftConstraint.constant = 1000; //offscreen initially
}

-(void)keyboardWillShow:(NSNotification*)note
{
	CGRect endFrame = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
		self.haveExternalKeyboard = endFrame.origin.y != 0;
	else
		self.haveExternalKeyboard = self.textField.inputAccessoryView.frame.size.height == 768 - endFrame.origin.x;
}

-(NSLayoutConstraint*)setupContentSubviewConstraints:(UIView*)subview
{
	UIView *parent = self.containerView;
	[parent addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:parent attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
	[parent addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:parent attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
	[parent addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:parent attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
	NSLayoutConstraint *x = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:parent attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
	[parent addConstraint:x];
	return x;
}

#pragma mark - meat & potatos

-(void)animateToWebview
{
	[UIView performWithoutAnimation:^{
		self.webLeftConstraint.constant = self.containerView.bounds.size.width;
	}];
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.webLeftConstraint.constant = 0;
		self.outputLeftConstraint.constant = - self.outputView.bounds.size.width;
		[self.containerView setNeedsUpdateConstraints];
		[self.containerView layoutIfNeeded];
	} completion:^(BOOL finished) {
		self.visibleOutputView = self.webView;
		self.backButton.enabled = YES;
	}];
}

-(void)animateBackToMainView
{
	[UIView performWithoutAnimation:^{
		self.outputLeftConstraint.constant = - self.containerView.bounds.size.width;
	}];
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.outputLeftConstraint.constant = 0;
		self.webLeftConstraint.constant = 900;
		[self.containerView setNeedsUpdateConstraints];
		[self.containerView layoutIfNeeded];
	} completion:^(BOOL finished) {
		self.visibleOutputView = self.outputView;
		self.backButton.enabled = NO;
		[self.webView removeFromSuperview];
		[self setupWebView];
	}];
}

-(void)saveSessionState:(RCSavedSession*)savedState
{
	NSError *err;
	NSTextStorage *text = self.outputView.textStorage;
	if (text.length > 0) {
		NSData *data = [text dataFromRange:NSMakeRange(0, text.length) documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFDTextDocumentType} error:&err];
		if (data)
			[savedState setProperty:data forKey:@"ConsoleRTF"];
		else
			Rc2LogError(@"error saving document data:%@", err);
	}
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	NSData *rtfdata = [savedState propertyForKey:@"ConsoleRTF"];
	NSError *err;
	if (rtfdata && ![self.outputView.textStorage readFromData:rtfdata options:nil documentAttributes:nil error:nil])
		Rc2LogError(@"error reading consolertf:%@", err);
}

-(void)sessionModeChanged
{
	[self adjustInterface];
}

-(void)loadHelpURL:(NSURL*)url
{
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)loadLocalFileURL:(NSURL*)url
{
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
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
		if (self.visibleOutputView != self.outputView)
			self.backButton.enabled = YES;
	}
}

-(void)appendAttributedString:(NSAttributedString*)aString
{
	NSUInteger curEnd = self.outputView.textStorage.length;
	[self.outputView.textStorage appendAttributedString:aString];
	[self.outputView.textStorage addAttribute:NSFontAttributeName value:self.baseFont range:NSMakeRange(curEnd, aString.length)];
	[self.outputView scrollRangeToVisible:NSMakeRange(self.outputView.textStorage.length-1, 1)];
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
	NSTextStorage *text = self.outputView.textStorage;
	[text deleteCharactersInRange:NSMakeRange(0, text.length)];
	[[RCImageCache sharedInstance] clearCache];
}

-(IBAction)doBack:(id)sender
{
	ZAssert(self.visibleOutputView != self.outputView, @"can't back from output view");
	if (self.visibleOutputView == self.webView && self.webView.canGoBack) {
		[self.webView goBack];
		return;
	}
	[self animateBackToMainView];
}

-(void)previewImage:(RCImageAttachment*)imgAttachment inRange:(NSRange)charRange
{
	ZAssert(charRange.length == 1, @"bad assumption");
	//find the line with the clicked attachment
	NSUInteger lineStart=0, lineEnd=0;
	[self.outputView.textStorage.string getLineStart:&lineStart end:NULL contentsEnd:&lineEnd forRange:charRange];
	NSRange attaachRange = NSMakeRange(lineStart, lineEnd - lineStart);
	//iterate all attachments in that range, adding to imgArray if they are an image
	NSMutableArray *imgArray = [NSMutableArray array];
	__block RCImage *selImage=nil;
	[self.outputView.textStorage enumerateAttribute:NSAttachmentAttributeName inRange:attaachRange options:0 usingBlock:^(id value, NSRange range, BOOL *stop)
	{
		if ([value isKindOfClass:[RCImageAttachment class]]) {
			RCImage *img = [[RCImageCache sharedInstance] imageWithId:[[value imageId] description]];
			if (img) {
				[imgArray addObject:img];
				if ([img.imageId isEqualToNumber:imgAttachment.imageId])
					selImage = img;
			}
		}
	}];
	//compute the rectangle the user tapped on
	NSRange grange = NSMakeRange([self.outputView.layoutManager glyphIndexForCharacterAtIndex:charRange.location], 1);
	CGRect startRect = [self.outputView.layoutManager boundingRectForGlyphRange:grange inTextContainer:self.outputView.textContainer];
	startRect = [self.view convertRect:startRect fromView:self.outputView];
	//create the preview controller and present it
	ImagePreviewViewController *pvc = [[ImagePreviewViewController alloc] init];
	pvc.images = imgArray;
	pvc.currentIndex = [imgArray indexOfObject:selImage];
	pvc.modalPresentationStyle = UIModalPresentationCustom;
	pvc.transitioningDelegate = self;
	objc_setAssociatedObject(pvc, @selector(previewImage:inRange:), [NSValue valueWithCGRect:startRect], OBJC_ASSOCIATION_RETAIN);
	[self setDefinesPresentationContext:YES];
	[self presentViewController:pvc animated:YES completion:nil];
}

-(void)previewFile:(RCFileAttachment*)fileAttachment inRange:(NSRange)charRange
{
	RCFile *file = [self.session.workspace fileWithId:fileAttachment.fileId];
	NSURL *furl = [NSURL fileURLWithPath:file.fileContentsPath];
	if (self.visibleOutputView != self.webView)
		[self animateToWebview];
	[self.webView loadRequest:[NSURLRequest requestWithURL:furl]];
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
	if ([presented isKindOfClass:[ImagePreviewViewController class]]) {
		ImagePreviewTransition *trans = [[ImagePreviewTransition alloc] init];
		NSValue *val = objc_getAssociatedObject(presented, @selector(previewImage:inRange:));
		trans.srcRect = [val CGRectValue];
		trans.presenting = self;
		trans.presented = presented;
		return trans;
	}
	return nil;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	if ([dismissed isKindOfClass:[ImagePreviewViewController class]]) {
		ImagePreviewTransition *trans = [[ImagePreviewTransition alloc] init];
		NSValue *val = objc_getAssociatedObject(dismissed, @selector(previewImage:inRange:));
		trans.srcRect = [val CGRectValue];
		trans.isDismissal = YES;
		return trans;
	}
	return nil;
}

#pragma mark - UITextView bug workaround

//textView:shouldInteractWithTextAttachment:inRange: is not called when an attachment is on the last row of
// the text view. Or maybe it isn't called for the last couple, no matter what. Either way, if the builtin
// gesture recognizer fails to fire, our secondary one does and we can figure out if it was a tap on a text
// attachment, and if so, call the textvview delegate method manually

-(void)textTapped:(UITapGestureRecognizer*)gesture
{
	NSUInteger gidx = [self.outputView.layoutManager glyphIndexForPoint:[gesture locationInView:self.outputView] inTextContainer:self.outputView.textContainer fractionOfDistanceThroughGlyph:NULL];
	NSUInteger cidx = [self.outputView.layoutManager characterIndexForGlyphAtIndex:gidx];
	NSRange rng = NSMakeRange(cidx, 1);
	id obj = [self.outputView.textStorage attribute:NSAttachmentAttributeName atIndex:cidx effectiveRange:NULL];
	if ([obj isKindOfClass:[NSTextAttachment class]])
		[self textView:self.outputView shouldInteractWithTextAttachment:obj inRange:rng];
}


#pragma mark - textview delegate
//called when an attachment is touched
-(BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
	if ([textAttachment isKindOfClass:[RCImageAttachment class]])
		[self previewImage:(RCImageAttachment*)textAttachment inRange:characterRange];
	else if ([textAttachment isKindOfClass:[RCFileAttachment class]])
		[self previewFile:(RCFileAttachment*)textAttachment inRange:characterRange];
	else
		Rc2LogWarn(@"unsupported text attachment class:%@", [textAttachment class]);
	return NO;
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
	self.webView.scalesPageToFit = NSOrderedSame == [self.webView.request.URL.pathExtension caseInsensitiveCompare:@"pdf"];
	[self adjustInterface];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
	navigationType:(UIWebViewNavigationType)navigationType
{
	if ([request.URL isFileURL])
		return YES;
	if ([[[request URL] scheme] isEqualToString:@"rc2img"]) {
		NSString *urlStr = request.URL.absoluteString;
		NSString *path = [request.URL path];
		if ([urlStr hasSuffix:@".pdf"]) {
			path = request.URL.absoluteString;
			path = [path substringFromIndex:[path lastIndexOf:@"/"]+1];
		} else if (![urlStr.pathExtension isEqualToString:@"png"]) {
			path = urlStr.lastPathComponent;
		}
		[self.session.delegate displayImage:path];
	} else if ([[[request URL] scheme] isEqualToString:@"rc2file"]) {
		[self.session.delegate displayLinkedFile:request.URL.path];
	} else if ([[[request URL] absoluteString] hasPrefix:@"http://rc2.stat.wvu.edu/"]) { //used to have help, no reason to not allow
		return YES;
	} else if ([[[request URL] absoluteString] hasPrefix:@"http://www.stat.wvu.edu/"]) { //for help pages
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
