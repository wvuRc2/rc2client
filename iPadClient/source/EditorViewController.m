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

@interface EditorViewController() {
	CGRect _oldTextFrame;
	CGFloat _oldHeight;
	BOOL _viewLoaded;
	BOOL _handUp;
}
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
@synthesize session=_session;

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
			[self.textView resignFirstResponder];
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
	_oldHeight=self.textView.bounds.size.height;
	CGRect frame = self.textView.frame;
	_oldTextFrame=frame;
	frame.size.height = keyboardTop-frame.origin.y;
	self.textView.frame=frame;
}

-(void)keyboardHiding:(NSNotification*)note
{
	NSDictionary *userInfo = [note userInfo];
	CGRect frame = self.textView.frame;
	frame.size.height=_oldHeight;
	NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval animationDuration;
	[animationDurationValue getValue:&animationDuration];
	// Animate the resize of the text view's frame in sync with the keyboard's appearance.
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
	self.textView.frame=frame;
	self.textView.frame = _oldTextFrame;
	[UIView commitAnimations]; 
	self.currentFile.localEdits = self.textView.text;
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


#pragma mark - meat & potatoes

-(void)updateDocumentState
{
	RCSession *session = [Rc2Server sharedInstance].currentSession;
	self.executeButton.enabled = self.textView.text.length > 0;
	self.syncButtonItem.enabled = session.hasWritePerm && self.currentFile.locallyModified;
	self.textView.font = [UIFont fontWithName:@"Inconsolata" size:18];
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	if (savedState.currentFile) {
		[self loadFile:savedState.currentFile];
	} else if ([savedState.inputText length] > 0) {
		self.textView.text = savedState.inputText;
	}
	[self updateDocumentState];
}

-(void)loadFileData:(RCFile*)file
{
	if (self.currentFile) {
		self.currentFile.localEdits = self.textView.text;
	}
	self.currentFile = file;
	self.docTitleLabel.text = file.name;
	if (file.currentContents.length < 1)
		NSLog(@"why is there an empty file?");
	self.textView.text = file.currentContents;
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
			[self loadFileData:nil];
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
	self.syncButtonItem.enabled = !limited;
	self.executeButton.enabled = !limited;
	self.openFileButtonItem.enabled = !limited;
	self.textView.editable = !limited;
}

#pragma mark - actions

-(IBAction)doExecute:(id)sender
{
	if ([self.currentFile.name hasSuffix:@".Rnw"])
		[[Rc2Server sharedInstance].currentSession executeSweave:self.currentFile.name script:self.textView.text];
	else
		[[Rc2Server sharedInstance].currentSession executeScript:self.textView.text scriptName:self.currentFile.name];
}

-(void)loadFile:(RCFile*)file
{
	[self loadFile:file showProgress:YES];	
}

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress
{
	[self.filePopover dismissPopoverAnimated:YES];
	if ([file.name hasSuffix:@".pdf"]) {
		[(Rc2AppDelegate*)TheApp.delegate displayPdfFile:file];
		return;
	} else if (!file.isTextFile) {
		//FIXME: need to do something else when file is not a text file. Likely a pdf file.
		return;
	}
	if (file.contentsLoaded) {
		[self loadFileData:file];
	} else {
		//need to load with a progress HUD
		UIView *rootView = self.view.superview;
		MBProgressHUD *hud = nil;
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
	self.textView.text = @"";
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
	self.textView.text = self.currentFile.fileContents;
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
			NSString *ext = [str pathExtension];
			if (![ext isEqualToString:@"R"] && ![ext isEqualToString:@"RnW"] && ![ext isEqualToString:@"txt"])
				str = [str stringByAppendingPathExtension:@"R"];
			NSManagedObjectContext *moc = [[UIApplication sharedApplication] valueForKeyPath:@"delegate.managedObjectContext"];
			RCFile *file = [RCFile insertInManagedObjectContext:moc];
			file.name = str;
			file.fileContents = @"";
			[[[Rc2Server sharedInstance] currentSession].workspace addFile:file];
			[self performSelectorOnMainThread:@selector(loadFile:) withObject:file waitUntilDone:NO];
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
	Rc2AppDelegate *del = [TheApp delegate];
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
		self.handButton.hidden = [obj currentUser].master;
	}];
	self.sessionHandToken = [sess addObserverForKeyPath:@"handRaised" task:^(id obj, NSDictionary *dict) {
		blockSelf.handButton.selected = ((RCSession*)obj).handRaised;
	}];
}

@synthesize textView;
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
@synthesize syncButtonItem;
@synthesize sessionKvoToken;
@synthesize handButton;
@synthesize sessionHandToken;
@synthesize currentAlert=_currentAlert;
@end
