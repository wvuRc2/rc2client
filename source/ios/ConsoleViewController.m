//
//  ConsoleViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import <objc/runtime.h>
#import "ConsoleViewController.h"
#import "RCSession.h"
#import "RCSavedSession.h"
#import "RCWorkspace.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"
#import "RCImageCache.h"
#import "RCImage.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCTextAttachment.h"
#import "MAKVONotificationCenter.h"
#import "VariableListViewController.h"
#import "ImagePreviewTransition.h"
#import "ImagePreviewViewController.h"
#import "ImageCollectionController.h"
#import "CXAlertView.h"

const CGFloat kAnimDuration = 0.5;

@interface ConsoleViewController()<UITextViewDelegate,UIViewControllerTransitioningDelegate> {
	BOOL _didSetGraphUrl;
}
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UITextView *outputView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) UIView *visibleOutputView;
@property (nonatomic, strong) UIView *modalDimmingView;
@property (nonatomic, strong) NSLayoutConstraint *outputLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *webLeftConstraint;
@property (nonatomic, strong) VariableListViewController *variableController;
@property (nonatomic, strong) UIPopoverController *varablePopover;
@property (nonatomic, strong) id sessionKvoToken;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIFont *baseFont;
@property (nonatomic, strong) ImagePreviewViewController *imagePreviewController;
@property (nonatomic, strong) ImageCollectionController *imageDetailsController;
@property (nonatomic, weak) RCFile *currentFile;
@property BOOL haveExternalKeyboard;
@property BOOL viewIsAnimating;
@property (nonatomic, copy) BasicBlock postAnimationBlock;
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileDeletion:) name:RC2FileDeletedNotification object:nil];
	
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
	
	self.modalDimmingView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.modalDimmingView.translatesAutoresizingMaskIntoConstraints = NO;
	self.modalDimmingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.05];
	self.modalDimmingView.opaque = NO;
	self.modalDimmingView.alpha = 0;
	[self.view addSubview:self.modalDimmingView];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_modalDimmingView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_modalDimmingView)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_modalDimmingView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_modalDimmingView)]];
	self.modalDimmingView.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	NSRange rng = NSMakeRange(self.outputView.textStorage.length-2, 1);
	[self.outputView scrollRangeToVisible:rng];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	if (self.imagePreviewController) {
		[self.imagePreviewController dismissViewControllerAnimated:YES completion:nil];
	}
}

-(void)setupWebView
{
	self.webView = [[UIWebView alloc] initWithFrame:self.containerView.bounds];
	self.webView.delegate = self;
	self.webView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.containerView addSubview:self.webView];
	self.webLeftConstraint = [self setupContentSubviewConstraints:self.webView];
	self.webLeftConstraint.constant = 1000; //offscreen initially
	self.webView.dataDetectorTypes = UIDataDetectorTypeLink;
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
	self.viewIsAnimating = YES;
	[UIView animateWithDuration:kAnimDuration animations:^{
		self.webLeftConstraint.constant = 0;
		self.outputLeftConstraint.constant = - self.outputView.bounds.size.width;
		[self.containerView setNeedsUpdateConstraints];
		[self.containerView layoutIfNeeded];
	} completion:^(BOOL finished) {
		self.visibleOutputView = self.webView;
		self.backButton.enabled = YES;
		self.viewIsAnimating = NO;
		if (self.postAnimationBlock) {
			RunAfterDelay(0.1, self.postAnimationBlock);
			self.postAnimationBlock=nil;
		}
	}];
}

-(void)animateBackToMainView
{
	[UIView performWithoutAnimation:^{
		self.outputLeftConstraint.constant = - self.containerView.bounds.size.width;
	}];
	self.viewIsAnimating = YES;
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
		self.viewIsAnimating = NO;
		if (self.postAnimationBlock) {
			RunAfterDelay(0.1, self.postAnimationBlock);
			self.postAnimationBlock=nil;
		}
	}];
}

-(void)saveSessionState:(RCSavedSession*)savedState
{
	NSTextStorage *text = [self.outputView.textStorage mutableCopy];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:text];
	if (data)
		savedState.consoleRtf = data;
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	NSTextStorage *text = self.outputView.textStorage;
	NSTextStorage *archText;
	@try {
		if (savedState.consoleRtf) {
			archText = [NSKeyedUnarchiver unarchiveObjectWithData:savedState.consoleRtf];
			[text replaceCharactersInRange:NSMakeRange(0, text.length) withAttributedString:archText];
		}
	}
	@catch (NSException *exception) {
		Rc2LogWarn(@"exception in restoreSessionState");
		NSLog(@"excep:%@", exception);
	}
}

-(void)sessionModeChanged
{
	[self adjustInterface];
}

-(void)loadHelpItems:(NSArray*)items topic:(NSString*)helpTopic
{
	if (self.viewIsAnimating) {
		__weak ConsoleViewController *bself = self;
		self.postAnimationBlock = ^{
			[bself loadHelpItems:items topic:helpTopic];
		};
		return;
	}
	if (items.count == 0) {
		//need to report error
	} else if (items.count == 1) {
		[self displayHelp:items[0][kHelpItemURL] topic:items[0][kHelpItemTitle]];
	} else { //multiple
		UITableView *table =  [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 300, 160) style:UITableViewStylePlain];
		[table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"helptable"];
		AMGenericTableViewHandler *handler = [[AMGenericTableViewHandler alloc] initWithTableView:table];
		handler.rowData = items;
		handler.prepareCellBlock = ^(AMGenericTableViewHandler *thandler, UITableView *btable, NSIndexPath *indexPath) {
			UITableViewCell *cell = [btable dequeueReusableCellWithIdentifier:@"helptable"];
			cell.textLabel.text = thandler.rowData[indexPath.row][@"title"];
			return cell;
		};
		table.separatorStyle = UITableViewCellSeparatorStyleNone;
		__block CXAlertView *alert = [[CXAlertView alloc] initWithTitle:@"Select Help Topic" contentView:table cancelButtonTitle:@"Cancel"];
		[alert addButtonWithTitle:@"Show" type:CXAlertViewButtonTypeDefault handler:^(CXAlertView *alertView, CXAlertButtonItem *button) {
			[alertView dismiss];
			NSIndexPath *ipath = handler.theTableView.indexPathForSelectedRow;
			if (ipath)
				[self displayHelp:items[ipath.row][kHelpItemURL] topic:items[ipath.row][kHelpItemTitle]];
		}];
		alert.showBlurBackground = YES;
		alert.cancelButtonFont = alert.buttonFont;
		//this is not really a retain cycle as the block is breaking the retain handler
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
		alert.didDismissHandler = ^(CXAlertView *alertView) {
			alert=nil;
		};
#pragma clang diagnostic pop
		[alert show];
	}
}

-(void)displayHelp:(NSURL*)url topic:(NSString*)helpTopic
{
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
	 {
		 if ([(NSHTTPURLResponse*)response statusCode] > 399) {
			 [self appendAttributedString:[self.session noHelpFoundString:helpTopic]];
		 } else {
			 if (self.visibleOutputView != self.webView)
				 [self animateToWebview];
			 [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
		 }
	 }];
}

-(void)loadLocalFile:(RCFile*)file
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:file.fileContentsPath]) {
		[file updateContentsFromServer:^(NSInteger success) {
			if (success)
				[self loadLocalFile:file];
		}];
		return;
	}
	if (self.visibleOutputView != self.webView)
		[self animateToWebview];
	self.currentFile = file;
	NSString *path = file.fileContentsPath;
	if (file.fileType.isTextFile && ![file.fileType.extension isEqualToString:@"txt"])
		path = [self.session pathForCopyForWebKitDisplay:file];
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
}

-(void)handleFileDeletion:(NSNotification*)note
{
	RCFile *file = note.object;
	if ([self.currentFile.fileId isEqualToNumber:file.fileId]) {
		self.currentFile=nil;
		[self animateBackToMainView];
	}
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
	if (self.visibleOutputView != self.outputView)
		[self animateBackToMainView];
	NSUInteger curEnd = self.outputView.textStorage.length;
	[self.outputView.textStorage appendAttributedString:aString];
	[self.outputView.textStorage addAttribute:NSFontAttributeName value:self.baseFont range:NSMakeRange(curEnd, aString.length)];
	[self.outputView scrollRangeToVisible:NSMakeRange(self.outputView.textStorage.length-1, 1)];
}

-(void)variablesUpdated
{
	[self.variableController variablesUpdated];
}

-(void)showImageDetailsForIndex:(NSUInteger)index images:(NSArray*)images
{
	if (nil == self.imageDetailsController) {
		self.imageDetailsController = [[ImageCollectionController alloc] init];
		self.imageDetailsController.navigationItem.title = [NSString stringWithFormat:@"%@ Images", self.session.workspace.name];
	}
	self.imageDetailsController.images = images;
	self.imageDetailsController.initialImageIndex = index;
	[self.navigationController pushViewController:self.imageDetailsController animated:YES];
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
			RCImage *img = [[RCImageCache sharedInstance] imageWithId:[[value imageId] integerValue]];
			if (img) {
				[imgArray addObject:img];
				if ([img.imageId isEqualToNumber:imgAttachment.imageId])
					selImage = img;
				[img image]; //start async loading
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
	pvc.detailsBlock = ^(ImagePreviewViewController *previewController) {
		[self dismissViewControllerAnimated:YES completion:^{
			[self showImageDetailsForIndex:previewController.currentIndex images:previewController.images];
		}];
	};
	self.modalDimmingView.alpha = 1;
	self.modalDimmingView.hidden = NO;
	[self presentViewController:pvc animated:YES completion:nil];
	self.imagePreviewController = pvc;
	pvc.dismissalBlock = ^(ImagePreviewViewController *controller) {
		self.imagePreviewController = nil;
		self.modalDimmingView.alpha = 0;
		[UIView animateWithDuration:0.2 animations:^{
			self.modalDimmingView.hidden = YES;
		}];
	};
}

-(void)previewFile:(RCFileAttachment*)fileAttachment inRange:(NSRange)charRange
{
	RCFile *file = [self.session.workspace fileWithId:fileAttachment.fileId];
	if (nil == file)
		return; //if it was deleted
	[self loadLocalFile:file];
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
	if ([[[request URL] absoluteString] hasPrefix:@"http://rc2.stat.wvu.edu/"]) { //used to have help, no reason to not allow
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
