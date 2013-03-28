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
#import "RCProject.h"
#import "RCSavedSession.h"
#import "RCSession.h"
#import "RCSessionUser.h"
#import "SessionFilesController.h"
#import "MBProgressHUD.h"
#import "DropboxImportController.h"
#import "SessionEditView.h"
#import "RCMSyntaxHighlighter.h"
#import "KeyboardToolbar.h"
#import "WHMailActivity.h"
#import <CoreText/CoreText.h>

@interface EditorViewController() <KeyboardToolbarDelegate> {
	BOOL _viewLoaded;
	BOOL _handUp;
}
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *executeButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *actionButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *openFileButtonItem;
@property (nonatomic, weak) IBOutlet UILabel *docTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *handButton;
@property (nonatomic, weak) IBOutlet SessionEditView *richEditor;
@property (nonatomic, strong) NSDictionary *defaultTextAttrs;
@property (nonatomic, strong) KeyboardToolbar *keyboardToolbar;
@property (nonatomic, strong) SessionFilesController *fileController;
@property (nonatomic, strong) UIPopoverController *filePopover;
@property (nonatomic, strong) UIPopoverController *activityPopover;
@property (nonatomic, strong) NSMutableArray *currentActionItems;
@property (nonatomic, strong) UINavigationController *importController;
@property (nonatomic, strong) NSMutableDictionary *dropboxCache;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIAlertView *currentAlert;
@property (nonatomic, strong) id sessionKvoToken;
@property (nonatomic, strong) id sessionHandToken;
@property BOOL syncInProgress;
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
	BOOL isLand = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
	if (isLand) {
		NSDictionary *userInfo = [note userInfo];
		CGSize kbsize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
		UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, kbsize.width, 0);
		self.richEditor.contentInset = insets;
		self.richEditor.scrollIndicatorInsets = insets;
	}
}

-(void)keyboardHiding:(NSNotification*)note
{
	self.richEditor.contentInset = UIEdgeInsetsZero;
	self.richEditor.scrollIndicatorInsets = UIEdgeInsetsZero;
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
		if ([self.richEditor respondsToSelector:@selector(attributedText)]) {
			self.defaultTextAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
									 [UIFont fontWithName:@"Inconsolata" size:18.0], NSFontAttributeName,
									 nil];
		}
		__weak EditorViewController *weakSelf = self;
		self.richEditor.helpBlock = ^(SessionEditView *editView) {
			//need to sanitize the input string. we'll just test for only alphanumeric
			NSString *str = [editView textInRange:editView.selectedTextRange];
			if (str && ![str containsCharacterNotInSet:[NSCharacterSet alphanumericCharacterSet]])
				[weakSelf.session executeScript:[NSString stringWithFormat:@"help(%@)", str] scriptName:nil];
		};
		self.richEditor.executeBlock = ^(SessionEditView *editView) {
			NSString *str = [editView textInRange:editView.selectedTextRange];
			if ([str length] > 0)
				[weakSelf.session executeScript:str scriptName:nil];
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

-(void)upArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionUp offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

-(void)downArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionDown offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

-(void)leftArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionLeft offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

-(void)rightArrow
{
	UITextPosition *pos = self.richEditor.selectedTextRange.start;
	pos = [self.richEditor positionFromPosition:pos inDirection:UITextLayoutDirectionRight offset:1];
	UITextRange *rng = [self.richEditor textRangeFromPosition:pos toPosition:pos];
	self.richEditor.selectedTextRange = rng;
}

#pragma mark - meat & potatoes

-(void)reloadFileData
{
	[self.fileController reloadData];
}

-(void)setInputView:(id)inputView
{
	self.richEditor.inputView = inputView;
}

-(BOOL)isEditorFirstResponder
{
	return self.richEditor.isFirstResponder;
}

-(void)editorResignFirstResponder
{
	[self.richEditor resignFirstResponder];
}

-(NSString*)editorContents
{
	return [self.richEditor.attributedString string];
}

-(void)updateDocumentState
{
	self.executeButton.enabled = self.richEditor.attributedString.length > 0;
	if (self.currentFile && _currentFile.readOnlyValue) {
		[self.richEditor setEditable:NO];
	} else {
		[self.richEditor setEditable:YES];
	}
	self.actionButtonItem.enabled = self.currentFile != nil && !self.session.restrictedMode;
}

-(void)restoreSessionState:(RCSavedSession*)savedState
{
	if (savedState.currentFile) {
		RCFile *file = [_session.workspace fileWithId:savedState.currentFile.fileId];
		if (file)
			[self loadFile:file];
	} else if ([savedState.inputText length] > 0) {
		[self updateTextContents:[[NSAttributedString alloc] initWithString:savedState.inputText]];
	}
	[self updateDocumentState];
}

-(void)loadFileData:(RCFile*)file
{
	RCFile *oldFile = _currentFile;
	if (self.currentFile != nil && self.currentFile != file) {
		self.currentFile.localEdits = self.richEditor.text;
	}
	if (nil == file) {
		Rc2LogWarn(@"asked to load file <nil>");
		self.currentFile=nil;
		self.docTitleLabel.text = @"";
		return;
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
	if (![oldFile.fileId isEqualToNumber:file.fileId]) {
		if (self.session.isClassroomMode && !self.session.restrictedMode) {
			[self.session sendFileOpened:file fullscreen:NO];
		}
	}
}

-(void)userConfirmedDelete:(RCFile*)file
{
	RCWorkspace *wspace = self.session.workspace;
	[[Rc2Server sharedInstance] deleteFile:file container:wspace completionHandler:^(BOOL success, id results) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (file == self.currentFile) {
				RCFile *nfile = wspace.files.firstObject;
				if (nil == nfile)
					nfile = wspace.project.files.firstObject;
				[self loadFileData:nfile];
				self.filePopover=nil;
			}
			[self.fileController reloadData];
			self.fileController=nil;
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
	dc.session = _session;
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
	self.actionButtonItem.enabled = !limited && nil != self.currentFile;
	self.executeButton.enabled = !limited;
	self.openFileButtonItem.enabled = !limited;
	self.richEditor.editable = !limited;
}

-(void)executeBlockAfterSave:(BasicBlock)block
{
	if (self.currentFile.locallyModified) {
		//force a sync of the file
		UIView *rootView = self.view.superview;
		MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
		hud.labelText = @"Sending File to Server…";
		self.syncInProgress = YES;
		[[Rc2Server sharedInstance] saveFile:self.currentFile 
								   toContainer:_session.workspace
						   completionHandler:^(BOOL success, id results) 
		{
			[MBProgressHUD hideHUDForView:rootView animated:YES];
			if (success) {
				[self.fileController.tableView reloadData];
				block();
			 } else {
				 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Saving"
																 message:results
																delegate:nil
													   cancelButtonTitle:@"OK"
													   otherButtonTitles:nil];
				 [alert show];
			 }
			 [self updateDocumentState];
			self.syncInProgress = NO;
		 }];
		
	} else {
		block();
	}
}

-(void)promptForNewFile:(BOOL)shared
{
	self.currentAlert = [[UIAlertView alloc] initWithTitle:(shared?@"New shared file name":@"New file name:") message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	__unsafe_unretained EditorViewController *blockSelf=self;
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		if (1!=btnIdx)
			return;
		//make sure has a file extension
		NSString *str = [alert textFieldAtIndex:0].text;
		if (str.length < 1)
			return;
		NSString *ext = [str pathExtension];
		if (![[Rc2Server acceptableTextFileSuffixes] containsObject:ext])
			str = [str stringByAppendingPathExtension:@"R"];
		NSManagedObjectContext *moc = [[UIApplication sharedApplication] valueForKeyPath:@"delegate.managedObjectContext"];
		RCFile *file = [RCFile insertInManagedObjectContext:moc];
		file.name = str;
		file.fileContents = @"";
		id<RCFileContainer> container = shared ? blockSelf.session.workspace.project : blockSelf.session.workspace;
		[[Rc2Server sharedInstance] saveFile:file toContainer:container completionHandler:^(BOOL success, id results) {
			if (success) {
				[self loadFile:results];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error creating file." message:results delegate:nil
													  cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
				[alert show];
			}
		}];
	}];
	self.currentAlert=nil;
}



#pragma mark - actions

-(IBAction)doExecute:(id)sender
{
	if ([self.richEditor isFirstResponder])
		[self.richEditor resignFirstResponder];
	if ([self.currentFile.name hasSuffix:@".sas"]) {
		[self executeBlockAfterSave:^{ [self.session executeSas:self.currentFile]; }];
	} else {
		[self executeBlockAfterSave:^{
			[_session executeScriptFile:self.currentFile];
		}];
	}
}

-(void)loadFile:(RCFile*)file
{
	[self loadFile:file showProgress:YES];	
}

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress
{
	if (self.syncInProgress)
		return;
	UIView *rootView = self.view.superview;
	MBProgressHUD *hud = nil;

	[self.filePopover dismissPopoverAnimated:YES];
	if ([file.name hasSuffix:@".pdf"]) {
		if (file.contentsLoaded) {
			[(Rc2AppDelegate*)TheApp.delegate displayPdfFile:file];
		} else {
			if (showProgress)
				hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
			hud.labelText = [NSString stringWithFormat:@"Loading %@…", file.name];
			[[Rc2Server sharedInstance] fetchFileContents:file completionHandler:^(BOOL success, id results) {
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
		Rc2LogWarn(@"EditorViewController asked to load unsupported file: %@", file.name);
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

-(IBAction)doActivityPopover:(id)sender
{
	if (self.activityPopover.isPopoverVisible) {
		[self.activityPopover dismissPopoverAnimated:YES];
		self.activityPopover = nil;
		return;
	}
	RCFile *file = self.currentFile;
	NSArray *excluded = @[UIActivityTypeMail,UIActivityTypeAssignToContact,UIActivityTypeMessage,UIActivityTypePostToFacebook,UIActivityTypePostToTwitter,UIActivityTypePostToWeibo];
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray *activs = [NSMutableArray arrayWithCapacity:5];
	if (self.currentFile.isTextFile)
		[items addObject:self.currentFile.fileContents];
	AMActivity *renameActivity = [[AMActivity alloc] initWithActivityType:@"edu.wvu.stat.rc2.renameActivity" title:@"Rename" image:@"renameActivity"];
	renameActivity.canPerformBlock = ^(NSArray *items) {
		return YES;
	};
	renameActivity.prepareBlock = ^(NSArray *items) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self doRenameFile:sender];
		});
	};
	[activs addObject:renameActivity];
	[items addObject:[WHMailActivityItem mailActivityItemWithSelectionHandler:^(MFMailComposeViewController *messageC) {
		[messageC setSubject:[NSString stringWithFormat:@"%@ from Rc²", file.name]];
		[messageC addAttachmentData:[NSData dataWithContentsOfFile:file.fileContentsPath]
						   mimeType:file.mimeType fileName:file.name];
	}]];
	[activs addObject:[[WHMailActivity alloc] init]];
	UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:activs];
	__weak UIActivityViewController *weakAvc = avc;
	avc.excludedActivityTypes = excluded;
	UIPopoverController *pop = [[UIPopoverController alloc] initWithContentViewController:avc];
	avc.completionHandler = ^(NSString *actType, BOOL completed) {
		weakAvc.completionHandler=nil;
		[self.activityPopover dismissPopoverAnimated:YES];
		self.activityPopover=nil;
	};
	self.activityPopover = pop;
	[pop presentPopoverFromBarButtonItem:self.actionButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)doActionMenu:(id)sender
{
	[self doActivityPopover:sender];
	return;
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
	if (_session.hasWritePerm) {
		if (self.currentFile) {
			[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Save" target:nil action:@selector(doSaveFile:) userInfo:nil]];
			[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Rename" target:nil action:@selector(doRenameFile:) userInfo:nil]];
			[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Delete" target:nil action:@selector(doDeleteFile:) userInfo:nil]];
		}
	}
	[self.currentActionItems addObject:[AMActionItem actionItemWithName:@"Revert" target:nil action:@selector(doRevertFile:) userInfo:nil]];
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"File Actions" delegate:(id)self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
	for (AMActionItem *action in self.currentActionItems)
		[self.actionSheet addButtonWithTitle:action.title];
	[self.actionSheet showFromBarButtonItem:sender animated:YES];
}

-(IBAction)doRenameFile:(id)sender
{
	self.currentAlert = [[UIAlertView alloc] initWithTitle:@"Rename file to:" message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[self.currentAlert textFieldAtIndex:0].text = self.currentFile.name;
	__unsafe_unretained EditorViewController *blockSelf=self;
	[self.currentAlert showWithCompletionHandler:^(UIAlertView *alert, NSInteger btnIdx) {
		NSString *str = [alert textFieldAtIndex:0].text;
		if (1==btnIdx && str.length > 0) {
			NSString *ext = [str pathExtension];
			if (![[Rc2Server acceptableTextFileSuffixes] containsObject:ext])
				str = [str stringByAppendingPathExtension:@"R"];
			[[Rc2Server sharedInstance] renameFile:blockSelf.currentFile toName:str completionHandler:^(BOOL success, id rsp) {
				if (success) {
					blockSelf.docTitleLabel.text = str;
					[self.fileController reloadData];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error renaming file" message:rsp delegate:nil
														  cancelButtonTitle:nil otherButtonTitles:@"Ok",nil];
					[alert show];
				}
			}];
		}
	}];
}

-(IBAction)doSaveFile:(id)sender
{
	UIView *rootView = self.view.superview;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
	hud.labelText = @"Saving…";
	self.syncInProgress=YES;
	[[Rc2Server sharedInstance] saveFile:self.currentFile 
							   toContainer:_session.workspace
					   completionHandler:^(BOOL success, id results) 
	{
		[MBProgressHUD hideHUDForView:rootView animated:YES];
		self.syncInProgress=NO;
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

-(IBAction)doNewSharedFile:(id)sender
{
	[self promptForNewFile:YES];
}

-(IBAction)doNewFile:(id)sender
{
	[self promptForNewFile:NO];
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
			[self userConfirmedDelete:[sender isKindOfClass:[RCFile class]] ? sender : self.currentFile];
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
	if (!self.session.hasReadPerm) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
														message:@"You do not have permission to read files in this workspace."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		return;
	}
	if (nil == self.fileController) {
		SessionFilesController *fc = [[SessionFilesController alloc] initWithSession:self.session];
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
	if ([self.richEditor respondsToSelector:@selector(attributedText)]) {
		NSMutableAttributedString *astr = [[[RCMSyntaxHighlighter sharedInstance] syntaxHighlightCode:srcStr ofType:self.currentFile.name.pathExtension] mutableCopy];
		[astr addAttributes:self.defaultTextAttrs range:NSMakeRange(0, astr.length)];
		srcStr = astr;
	}
	self.richEditor.attributedString = srcStr;
	[self.keyboardToolbar switchToPanelForFileExtension:self.currentFile.name.pathExtension];
}

- (void)textViewDidChange:(UITextView *)tview
{
	[self updateDocumentState];
}

#pragma mark - accessors

-(void)setSession:(RCSession*)sess
{
	self.sessionKvoToken = nil;
	_session = sess;
	__unsafe_unretained EditorViewController *blockSelf = self;
	self.sessionKvoToken = [sess addObserverForKeyPath:@"restrictedMode" task:^(id obj, NSDictionary *dict) {
		[blockSelf sessionModeChanged];
		//only show in classroom mode if not the master
		blockSelf.handButton.hidden = !((RCSession*)obj).isClassroomMode || [obj currentUser].master;
	}];
	self.sessionHandToken = [sess addObserverForKeyPath:@"handRaised" task:^(id obj, NSDictionary *dict) {
		blockSelf.handButton.selected = ((RCSession*)obj).handRaised;
	}];
}

@end
