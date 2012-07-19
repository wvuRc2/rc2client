//
//  EditorViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import "EditorViewController.h"
#import "Rc2Server.h"
#import "Rc2AppDelegate.h"
#import "RCSession.h"
#import "RCFile.h"
#import "RCWorkspace.h"
#import "RCSavedSession.h"
#import "RCSession.h"
#import "RCSessionUser.h"
#import "SessionFilesController.h"
#import "MBProgressHUD.h"
#import "DropboxImportController.h"
#import "SessionEditView.h"
#import "RCMSyntaxHighlighter.h"
#import "KeyboardToolbar.h"
#import <CoreText/CoreText.h>

@interface EditorViewController() <KeyboardToolbarDelegate> {
	CGRect _oldTextFrame;
	CGFloat _oldHeight;
	BOOL _viewLoaded;
	BOOL _handUp;
}
@property (nonatomic, strong) IBOutlet SessionEditView *richEditor;
@property (nonatomic, strong) NSDictionary *defaultTextAttrs;
@property (nonatomic, strong) KeyboardToolbar *keyboardToolbar;
@property (nonatomic, strong) SessionFilesController *fileController;
@property (nonatomic, strong) UIPopoverController *filePopover;
@property (nonatomic, strong) NSMutableArray *currentActionItems;
@property (nonatomic, strong) UINavigationController *importController;
@property (nonatomic, strong) NSMutableDictionary *dropboxCache;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIAlertView *currentAlert;
@property (nonatomic, strong) id sessionKvoToken;
@property (nonatomic, strong) id sessionHandToken;
-(void)keyboardVisible:(NSNotification*)note;
-(void)keyboardHiding:(NSNotification*)note;
-(void)updateDocumentState;
-(void)doDropBoxImport;
@end

@implementation EditorViewController

- (id)init
{
    self = [super initWithNibName:@"EditorViewController" bundle:nil];
    if (self) {
        self.currentActionItems = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleKeyCode:(unichar)code
{
	switch (code) {
		case 0xeaa0: //execute
			[self.richEditor resignFirstResponder];
			[self doExecute:self];
			break;
	}
}

-(void)keyboardVisible:(NSNotification*)note
{
	NSDictionary *userInfo = [note userInfo];
	NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [aValue CGRectValue];
	keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	CGFloat keyboardTop = keyboardRect.origin.y;
	_oldHeight=self.richEditor.bounds.size.height;
	CGRect frame = self.richEditor.frame;
	_oldTextFrame=frame;
	frame.size.height = keyboardTop-frame.origin.y;
	self.richEditor.frame=frame;
}

-(void)keyboardHiding:(NSNotification*)note
{
	NSDictionary *userInfo = [note userInfo];
	CGRect frame = self.richEditor.frame;
	frame.size.height=_oldHeight;
	NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval animationDuration;
	[animationDurationValue getValue:&animationDuration];
	// Animate the resize of the text view's frame in sync with the keyboard's appearance.
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
	self.richEditor.frame=frame;
	self.richEditor.frame = _oldTextFrame;
	[UIView commitAnimations]; 
	self.currentFile.localEdits = self.richEditor.text;
	[self updateDocumentState];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!_viewLoaded) {
		[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardVisible:)
												 name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(keyboardHiding:)
												 name:UIKeyboardWillHideNotification object:nil];
		self.docTitleLabel.text = @"Untitled Document";
		self.richEditor.font = [UIFont fontWithName:@"Inconsolata" size:18.0];
		self.defaultTextAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
								 [UIFont fontWithName:@"Inconsolata" size:18.0], NSFontAttributeName,
								 nil];
		self.richEditor.helpBlock = ^(SessionEditView *editView) {
			//FIXME: need to sanitize the input string
			NSString *str = [editView textInRange:editView.selectedTextRange];
			if (str)
				[[Rc2Server sharedInstance].currentSession executeScript:[NSString stringWithFormat:@"help(%@)", str] scriptName:nil];
		};
		self.keyboardToolbar = [[KeyboardToolbar alloc] init];
		self.keyboardToolbar.delegate = self;
		self.richEditor.inputAccessoryView = self.keyboardToolbar.view;
		self.richEditor.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.richEditor.autocorrectionType = UITextAutocorrectionTypeNo;
		self.richEditor.layer.masksToBounds=YES;
		_viewLoaded=YES;
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	_viewLoaded=NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.fileController=nil;
	self.filePopover=nil;
	self.importController=nil;
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

#pragma mark - keybard toolbar delegate

-(void)keyboardToolbar:(KeyboardToolbar*)tbar insertString:(NSString*)str
{
	NSMutableAttributedString *astr = [self.richEditor.attributedString mutableCopy];
	NSRange rng = self.richEditor.selectedRange;
	[astr replaceCharactersInRange:rng withString:str];
	self.richEditor.attributedString = astr;
	self.richEditor.selectedRange = NSMakeRange(rng.location + str.length, 0);
}

-(void)keyboardToolbarExecute:(KeyboardToolbar*)tbar
{
	[self.richEditor resignFirstResponder];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self doExecute:tbar];
	});
}

//doesn't work with rich editor.
-(void)arrowUp
{
	UITextRange *curRange = self.richEditor.selectedTextRange;
	UITextRange *extRange = [self.richEditor characterRangeByExtendingPosition:curRange.start inDirection:UITextLayoutDirectionDown];
	UITextRange *newRange = [self.richEditor textRangeFromPosition:extRange.start toPosition:extRange.start];
	self.richEditor.selectedTextRange = newRange;
}

#pragma mark - meat & potatoes

-(void)setInputView:(id)inputView
{
	self.richEditor.inputView = inputView;
}

-(BOOL)isEditorFirstResponder
{
	return self.richEditor.isFirstResponder;
}

-(NSString*)editorContents
{
	return [self.richEditor.attributedString string];
}

-(void)updateDocumentState
{
	self.executeButton.enabled = self.richEditor.attributedString.length > 0;
	if (self.currentFile && currentFile.readOnlyValue) {
		[self.richEditor setEditable:NO];
	} else {
		[self.richEditor setEditable:YES];
	}
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	if (savedState.currentFile) {
		[self loadFile:savedState.currentFile];
	} else if ([savedState.inputText length] > 0) {
		[self updateTextContents:[[NSAttributedString alloc] initWithString:savedState.inputText]];
	}
	[self updateDocumentState];
}

-(void)loadFileData:(RCFile*)file
{
	if (self.currentFile != nil && self.currentFile != file) {
		self.currentFile.localEdits = self.richEditor.attributedString.string;
	}
	self.currentFile = file;
	self.docTitleLabel.text = file.name;
	if (file.currentContents.length < 1) {
		file.localEdits = @"\n"; //if empty, our default font won't be used by richEditor
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.richEditor becomeFirstResponder]; //since it is an empty file, let them start filling it
		});
	}
	[self updateTextContents:[[NSAttributedString alloc] initWithString:file.currentContents]];
	[self updateDocumentState];
	if (self.session.isClassroomMode && !self.session.restrictedMode) {
		[self.session sendFileOpened:file];
	}
}

-(void)userConfirmedDelete
{
	RCWorkspace *wspace = [[Rc2Server sharedInstance] selectedWorkspace];
	[[Rc2Server sharedInstance] deleteFile:self.currentFile workspace:wspace completionHandler:^(BOOL success, id results) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSManagedObjectContext *moc = self.currentFile.managedObjectContext;
			[moc deleteObject:self.currentFile];
			[self loadFileData:self.session.workspace.files.firstObject];
			//FIXME: shouldn't need to refresh when all we did was delete a file
			[[[Rc2Server sharedInstance] currentSession].workspace refreshFiles];
			self.fileController=nil;
			self.filePopover=nil;
		});
	}];
}

-(void)userDone:(RCFile*)lastImport
{
	[self dismissModalViewControllerAnimated:YES];
	self.importController=nil;
	[self.dropboxCache removeAllObjects];
	[self.fileController reloadData];
	if (lastImport) {
		if (lastImport.isTextFile)
			[self loadFileData:lastImport];
		self.fileController=nil;
		self.filePopover=nil;
	}
	self.importController=nil;
}

-(void)doDropBoxImport
{
	if (nil == self.dropboxCache)
		self.dropboxCache = [NSMutableDictionary dictionary];
	[self.dropboxCache removeAllObjects];
	DropboxImportController *dc = [[DropboxImportController alloc] init];
	dc.dropboxCache = self.dropboxCache;
	self.importController = [[UINavigationController alloc] initWithRootViewController:dc];
	self.importController.modalPresentationStyle = UIModalPresentationFormSheet;
	self.importController.view.frame = CGRectMake(0, 0, 400, 600);
	self.importController.delegate = (id)self;

	CGSize sz = self.importController.view.frame.size;
	[self presentModalViewController: self.importController animated:YES];
	//center the modal view
	self.importController.view.superview.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
	| UIViewAutoresizingFlexibleBottomMargin;
	CGRect r = self.importController.view.superview.frame;
	r.size = sz;
	self.importController.view.superview.frame = r;
	CGPoint centerPt = CGPointZero;
	if (UIInterfaceOrientationIsLandscape(TheApp.statusBarOrientation)) {
		centerPt.x = 512;
		centerPt.y = 100 + floor(sz.height/2);
	} else {
		centerPt.x = 384;
		centerPt.y = 100 + floor(sz.height/2);		
	}
	self.importController.view.superview.center = centerPt;
}

-(void)sessionModeChanged
{
	bool limited = self.session.restrictedMode;
	self.actionButtonItem.enabled = !limited;
	self.executeButton.enabled = !limited;
	self.openFileButtonItem.enabled = !limited;
	self.richEditor.editable = !limited;
}

-(void)executeSas
{
	if (self.currentFile.locallyModified) {
		//force a sync of the file
		UIView *rootView = self.view.superview;
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
		hud.labelText = @"Sending File to Server…";
		[[Rc2Server sharedInstance] saveFile:self.currentFile 
								   workspace:[[Rc2Server sharedInstance] currentSession].workspace 
						   completionHandler:^(BOOL success, id results) 
		 {
			 [MBProgressHUD hideHUDForView:rootView animated:YES];
			 if (success) {
				 [self.fileController.tableView reloadData];
				 [self.session executeSas:self.currentFile];
			 } else {
				 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Saving"
																 message:results
																delegate:nil
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil];
				 [alert show];
			 }
			 [self updateDocumentState];
		 }];
		
	} else {
		[self.session executeSas:self.currentFile];
	}
}

#pragma mark - actions

-(IBAction)doExecute:(id)sender
{
	if ([self.richEditor isFirstResponder])
		[self.richEditor resignFirstResponder];
	NSString *src = self.richEditor.attributedString.string;
	if ([self.currentFile.name hasSuffix:@".Rnw"])
		[[Rc2Server sharedInstance].currentSession executeSweave:self.currentFile.name script:src];
	else if ([self.currentFile.name hasSuffix:@".sas"])
		[self executeSas];
	else if ([self.currentFile.name hasSuffix:@".Rmd"])
		[[Rc2Server sharedInstance].currentSession executeSweave:self.currentFile.name script:src];
	else
		[[Rc2Server sharedInstance].currentSession executeScript:src scriptName:self.currentFile.name];
}

-(void)loadFile:(RCFile*)file
{
	[self loadFile:file showProgress:YES];	
}

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress
{
	UIView *rootView = self.view.superview;
	MBProgressHUD *hud = nil;

	[self.filePopover dismissPopoverAnimated:YES];
	if ([file.name hasSuffix:@".pdf"]) {
		if (file.contentsLoaded)
			[(Rc2AppDelegate*)TheApp.delegate displayPdfFile:file];
		else {
			if (showProgress)
				hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
			hud.labelText = [NSString stringWithFormat:@"Loading %@…", file.name];
			[[Rc2Server sharedInstance] fetchBinaryFileContents:file toPath:file.fileContentsPath progress:nil 
											  completionHandler:^(BOOL success, id results)
			{
				if (showProgress)
					[MBProgressHUD hideHUDForView:rootView animated:YES];
				if (success)
					[self loadFile:file showProgress:showProgress];
				else
					Rc2LogWarn(@"failed to fetch pdf '%@' from server:%@", file.name, results);
			}];
		}
		return;
	} else if (!file.isTextFile) {
		//FIXME: need to do something else when file is not a text file. Likely a pdf file.
		return;
	}
	if (file.contentsLoaded) {
		[self loadFileData:file];
	} else {
		//need to load with a progress HUD
		if (showProgress)
			hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
		hud.labelText = @"Loading…";
		[[Rc2Server sharedInstance] fetchFileContents:file completionHandler:^(BOOL success, id results) {
			file.fileContents = results;
			[self loadFileData:file];
			if (showProgress)
				[MBProgressHUD hideHUDForView:rootView animated:YES];
		}];
	}
}

-(IBAction)doClear:(id)sender
{
	self.docTitleLabel.text = @"Untitled Document";
	self.richEditor.attributedString = [[NSAttributedString alloc] initWithString:@""];
	self.currentFile=nil;
	[self updateDocumentState];
}

-(IBAction)doActionMenu:(id)sender
{
	if (self.actionSheet.visible) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
		return;
	}
	if (self.filePopover.popoverVisible) {
		[self.filePopover dismissPopoverAnimated: YES];
	}
	if (nil == self.currentActionItems)
		self.currentActionItems = [NSMutableArray array];
	[self.currentActionItems removeAllObjects];
	RCSession *session = [Rc2Server sharedInstance].currentSession;
	if (session.hasWritePerm) {
		[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"New File" target:nil action:@selector(doNewFile:) userInfo:nil]];
		if (self.currentFile)
			[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Save File on Server" target:nil action:@selector(doSaveFile:) userInfo:nil]];
		[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Delete File on Server" target:nil action:@selector(doDeleteFile:) userInfo:nil]];
	}
	if (session.hasReadPerm) {
		[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Revert File" target:nil action:@selector(doRevertFile:) userInfo:nil]];
	}
	[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Clear Editor" target:nil action:@selector(doClear:) userInfo:nil]];
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Editor Actions" delegate:(id)self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	for (AMActionItem *action in self.currentActionItems)
		[self.actionSheet addButtonWithTitle:action.title];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

-(IBAction)doSaveFile:(id)sender
{
	UIView *rootView = self.view.superview;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
	hud.labelText = @"Saving…";
	[[Rc2Server sharedInstance] saveFile:self.currentFile 
							   workspace:[[Rc2Server sharedInstance] currentSession].workspace 
					   completionHandler:^(BOOL success, id results) 
	{
		[MBProgressHUD hideHUDForView:rootView animated:YES];
		if (success) {
			[self.fileController.tableView reloadData];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Saving"
															message:results
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		[self updateDocumentState];
	}];
}

-(IBAction)doRevertFile:(id)sender
{
	[self.currentFile discardEdits];
	[self updateTextContents:[[NSAttributedString alloc] initWithString:self.currentFile.currentContents]];
	[self updateDocumentState];
}

-(IBAction)doNewFile:(id)sender
{
	self.currentAlert = [[UIAlertView alloc] initWithTitle:@"New File Name:" message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	__unsafe_unretained EditorViewController *blockSelf=self;
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (1==btnIdx) {
			[(UIPopoverController*)self.parentViewController dismissPopoverAnimated:YES];
			//make sure has a file extension
			NSString *str = [alert textFieldAtIndex:0].text;
			if (str.length > 0) {
				NSString *ext = [str pathExtension];
				if (![[Rc2Server acceptableTextFileSuffixes] containsObject:ext])
					str = [str stringByAppendingPathExtension:@"R"];
				NSManagedObjectContext *moc = [[UIApplication sharedApplication] valueForKeyPath:@"delegate.managedObjectContext"];
				RCFile *file = [RCFile insertInManagedObjectContext:moc];
				file.name = str;
				file.fileContents = @"";
				[[[Rc2Server sharedInstance] currentSession].workspace addFile:file];
				[self performSelectorOnMainThread:@selector(loadFile:) withObject:file waitUntilDone:NO];
			}
		}
		blockSelf.currentAlert=nil;
	}];
}

-(void)doDeleteFile:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this file?"
													message:@"This will delete the file on the server and there will be no way to undo this action."
												   delegate:nil
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"Delete",nil];
	[alert showWithCompletionHandler:^(UIAlertView *aview, NSInteger buttonIndex) {
		if (buttonIndex == 1)
			[self userConfirmedDelete];
	}];
}

-(IBAction)presentDropboxImport:(id)sender
{
	Rc2AppDelegate *del = (Rc2AppDelegate*)[TheApp delegate];
	if ([[DBSession sharedSession] isLinked]) {
		del.dropboxCompletionBlock = nil;
		[self doDropBoxImport];
	} else {
		//we need to prompt the user to link to us. we need to let the app delegate know
		//to call this object/action on a successful link
		__weak EditorViewController *blockSelf = self;
		del.dropboxCompletionBlock = ^{
			if (blockSelf.view.window)
				[blockSelf presentDropboxImport:blockSelf];
		};
		[[DBSession sharedSession] link];
	}
}

-(IBAction)doShowFiles:(id)sender
{
	if (self.filePopover.popoverVisible) {
		[self.filePopover dismissPopoverAnimated: YES];
		return;
	}
	if (self.actionSheet.visible) {
		[self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
	}
	if (![[Rc2Server sharedInstance] currentSession].hasReadPerm) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
														message:@"You do not have permission to read files in this workspace."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
	if (nil == self.fileController) {
		SessionFilesController *fc = [[SessionFilesController alloc] init];
		self.fileController = fc;
		fc.delegate = (id)self;
		UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:fc];
		self.filePopover = pc;
		pc.delegate=self;
	}
	[self.fileController.tableView reloadData];
	[self.filePopover presentPopoverFromBarButtonItem:sender 
							 permittedArrowDirections:UIPopoverArrowDirectionAny 
											 animated:YES];
}

-(IBAction)toggleHand:(id)sender
{
	if (self.session.handRaised)
		[self.session lowerHand];
	else
		[self.session raiseHand];
}

#pragma mark - delegate methods

-(void)dismissSessionsFilesController
{
	[self.filePopover dismissPopoverAnimated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0)
		return;
	AMActionItem *action = [self.currentActionItems objectAtIndex:buttonIndex];
	//ARC needs to know the selector to properly use retain/release. we know this isn't returning anything, so
	// there is no need to worry
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self performSelector:action.action withObject:self.actionButtonItem];
#pragma clang diagnostic pop
	self.actionSheet=nil;
}

- (void)richTextChanged:(NSNotification*)note
{
	[self updateTextContents:nil];
}

-(void)updateTextContents:(NSAttributedString*)srcStr
{
	if (nil == srcStr)
		srcStr = self.richEditor.attributedString;
	NSMutableAttributedString *astr = [[[RCMSyntaxHighlighter sharedInstance] syntaxHighlightCode:srcStr ofType:self.currentFile.name.pathExtension] mutableCopy];
	[astr addAttributes:self.defaultTextAttrs range:NSMakeRange(0, astr.length)];
	self.richEditor.attributedString = astr;
	[self.keyboardToolbar switchToPanelForFileExtension:self.currentFile.name.pathExtension];
}

- (void)textViewDidChange:(UITextView *)tview
{
	[self updateDocumentState];
}

#pragma mark - synthesizers

-(void)setSession:(RCSession*)sess
{
	self.sessionKvoToken = nil;
	_session = sess;
	__unsafe_unretained EditorViewController *blockSelf = self;
	self.sessionKvoToken = [sess addObserverForKeyPath:@"restrictedMode" task:^(id obj, NSDictionary *dict) {
		[blockSelf sessionModeChanged];
		blockSelf.handButton.hidden = [obj currentUser].master;
	}];
	self.sessionHandToken = [sess addObserverForKeyPath:@"handRaised" task:^(id obj, NSDictionary *dict) {
		blockSelf.handButton.selected = ((RCSession*)obj).handRaised;
	}];
}

@synthesize session=_session;
@synthesize richEditor=_richEditor;
//@synthesize textView;
@synthesize fileController;
@synthesize filePopover;
@synthesize docTitleLabel;
@synthesize actionButtonItem;
@synthesize openFileButtonItem;
@synthesize currentFile;
@synthesize executeButton;
@synthesize currentActionItems;
@synthesize importController;
@synthesize dropboxCache;
@synthesize actionSheet;
@synthesize sessionKvoToken;
@synthesize handButton;
@synthesize sessionHandToken;
@synthesize defaultTextAttrs=_defaultTextAttrs;
@synthesize currentAlert=_currentAlert;
@synthesize keyboardToolbar=_keyboardToolbar;
@synthesize toolbar=_toolbar;
@end
