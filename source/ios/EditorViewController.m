//
//  EditorViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright (c) 2011 University of West Virginia. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "EditorViewController.h"
#import "Rc2Server.h"
#import "Rc2AppDelegate.h"
#import "RCSession.h"
#import "RCFile.h"
#import "Rc2FileType.h"
#import "RCWorkspace.h"
#import "RCProject.h"
#import "RCSavedSession.h"
#import "RCSession.h"
#import "RCSessionUser.h"
#import "SessionFilesController.h"
#import "MBProgressHUD.h"
#import "DropboxImportController.h"
#import "SessionEditView.h"
#import "kTController.h"
#import "WHMailActivity.h"
#import "MAKVONotificationCenter.h"
#import "RCSyntaxParser.h"
#import "DrropboxUploadActivity.h"
#import "DropboxFolderSelectController.h"
#import "DropBlocks.h"
#import "SessionEditorCotnainerView.h"

#define DEFAUT_UIFONT [UIFont fontWithName:@"Inconsolata" size:18.0]

@interface EditorViewController() <KTControllerDelegate,NSTextStorageDelegate> {
	CGRect _oldRect;
	BOOL _viewLoaded;
	BOOL _handUp;
}
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *executeButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *actionButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *openFileButtonItem;
@property (nonatomic, weak) IBOutlet UILabel *docTitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *handButton;
//@property (nonatomic, weak) IBOutlet UITextView *lineNumberView;
@property (nonatomic, weak) IBOutlet SessionEditorCotnainerView *editorContainer;
@property (nonatomic, strong) IBOutlet SessionEditView *richEditor;
@property (nonatomic, strong) NSDictionary *defaultTextAttrs;
@property (nonatomic, strong) kTController *keyboardToolbar;
@property (nonatomic, strong) SessionFilesController *fileController;
@property (nonatomic, strong) UIPopoverController *filePopover;
@property (nonatomic, strong) UIPopoverController *activityPopover;
@property (nonatomic, strong) NSMutableArray *currentActionItems;
@property (nonatomic, strong) UINavigationController *importController;
@property (nonatomic, strong) NSMutableDictionary *dropboxCache;
@property (nonatomic, strong) UIAlertView *currentAlert;
@property (nonatomic, strong) NSTimer *widthAdjustTimer;
@property (nonatomic, strong) RCSyntaxParser *syntaxParser;
@property (atomic) BOOL isParsing;
@property int32_t syncInProgress;
@property (nonatomic) NSTimeInterval lastParseTime;
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

-(void)keyboardWillShow:(NSNotification*)note
{
	if (!self.richEditor.isBecomingFirstResponder)
		return;
	NSDictionary *info = note.userInfo;
	CGRect keyframe = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyframe = [self.view.window.rootViewController.view convertRect:keyframe fromView:nil];
	BOOL isLand = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
	self.externalKeyboardVisible = NO;
	if (isLand) {
		if (keyframe.origin.x < 0)
			self.externalKeyboardVisible = YES;
	} else if (keyframe.origin.y + self.keyboardToolbar.view.frame.size.height > 1000) {
		self.externalKeyboardVisible = YES;
	}

    double duration = [(NSNumber *)[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    unsigned int curve = [(NSNumber *)[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue];
    
    UIEdgeInsets contentInset = self.richEditor.contentInset;
    UIEdgeInsets scrollInset = self.richEditor.scrollIndicatorInsets;
    contentInset.bottom += keyframe.size.height;
    scrollInset.bottom += keyframe.size.height;
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:curve
                     animations:^{
                         self.richEditor.contentInset = contentInset;
                         self.richEditor.scrollIndicatorInsets = scrollInset;
                     }
                     completion:^(BOOL s){ /*[self scrollSelectionVisible:YES];*/}];
}

-(void)keyboardHiding:(NSNotification*)note
{
	NSDictionary *info = note.userInfo;
	self.currentFile.localEdits = self.richEditor.text;
	[self updateDocumentState];
	self.richEditor.inputAccessoryView = self.keyboardToolbar.inputView;
	if (self.currentFile.locallyModified && self.currentFile.localEdits.length < 4096)
		[self saveFileData:nil];

    double duration = [(NSNumber *)[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    unsigned int curve = [(NSNumber *)[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue];
	CGRect keyframe = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyframe = [self.view.window.rootViewController.view convertRect:keyframe fromView:nil];
    CGFloat keyHeight = keyframe.size.height;
    UIEdgeInsets contentInset = self.richEditor.contentInset;
    UIEdgeInsets scrollInset = self.richEditor.scrollIndicatorInsets;
    contentInset.bottom -= keyHeight;
    scrollInset.bottom -= keyHeight;
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:curve
                     animations:^{
                         self.richEditor.contentInset = contentInset;
                         self.richEditor.scrollIndicatorInsets = scrollInset;
//						 self.lineNumberView.contentInset = contentInset;
//						 self.lineNumberView.scrollIndicatorInsets = scrollInset;
                     }
                     completion:nil]; 
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!_viewLoaded) {
		self.richEditor = self.editorContainer.textView;
		self.richEditor.delegate = self;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardHiding:)
												 name:UIKeyboardWillHideNotification object:nil];
		self.docTitleLabel.text = @"Untitled Document";
		UIFontDescriptor *sysFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
		UIFont *myFont = [UIFont fontWithName:@"Inconsolata" size:sysFont.pointSize];
		self.richEditor.font = myFont;
		self.defaultTextAttrs = @{NSFontAttributeName:DEFAUT_UIFONT};
		self.docTitleLabel.font = DEFAUT_UIFONT;
		self.richEditor.layoutManager.allowsNonContiguousLayout = NO; //solves bug with inability to calculate how many lines to show proper scroll indicator position
		
		__weak EditorViewController *weakSelf = self;
		self.richEditor.helpBlock = ^(SessionEditView *editView) {
			//need to sanitize the input string. we'll just test for only alphanumeric
			NSString *str = [editView.text substringWithRange:editView.selectedRange];
			if (str && ![str containsCharacterNotInSet:[NSCharacterSet alphanumericCharacterSet]])
				[weakSelf.session executeScript:[NSString stringWithFormat:@"help(%@)", str] scriptName:nil];
			if (!weakSelf.externalKeyboardVisible)
				[editView resignFirstResponder];
		};
		self.richEditor.executeBlock = ^(SessionEditView *editView) {
			if (editView.selectedRange.length < 1) {
				//execute the line
				NSString *str = [[editView.text substringWithRange:[editView.text lineRangeForRange:editView.selectedRange]] stringByTrimmingWhitespace];
				if ([str length] > 0)
					[weakSelf.session executeScript:str scriptName:nil];
			} else {
				//excute selecction
				NSString *str = [[editView.text substringWithRange:editView.selectedRange] stringByTrimmingWhitespace];
				if ([str length] > 0)
					[weakSelf.session executeScript:str scriptName:nil];
			}
			if (!weakSelf.externalKeyboardVisible)
				[editView resignFirstResponder];
		};
		[[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note)
		{
			UIFontDescriptor *stdFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
			UIFont *myFont = [UIFont fontWithName:@"Inconsolata" size:stdFont.pointSize];
			weakSelf.richEditor.font = myFont;
		}];
		
		self.richEditor.textStorage.delegate = self;
		
		self.handButton.hidden = YES;
		self.keyboardToolbar = [[kTController alloc] initWithDelegate:self];
		self.richEditor.inputAccessoryView = self.keyboardToolbar.inputView;
		_viewLoaded=YES;
	}
}

#pragma mark - keybard toolbar delegate

-(BOOL)kt_enableButtonWithSelector:(SEL)sel
{
	return YES;
}

-(void)kt_insertString:(NSString *)string
{
	NSRange rng = self.richEditor.selectedRange;
	[self.richEditor.textStorage replaceCharactersInRange:rng withString:string];
}

-(void)kt_execute:(id)sender
{
	[self.richEditor resignFirstResponder];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self internalExecute:RCSessionExecuteOptionNone];
		if (!self.externalKeyboardVisible)
			[self.richEditor resignFirstResponder];
	});
}

-(void)kt_source:(id)sender
{
	[self.richEditor resignFirstResponder];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self internalExecute:RCSessionExecuteOptionSource];
		if (!self.externalKeyboardVisible)
			[self.richEditor resignFirstResponder];
	});
}

-(void)kt_executeLine:(id)sender
{
	SessionEditView *editor = self.richEditor;
	NSString *str = [[editor.text substringWithRange:[editor.text lineRangeForRange:editor.selectedRange]] stringByTrimmingWhitespace];
	if ([str length] > 0)
		[self.session executeScript:str scriptName:nil];
	if (!self.externalKeyboardVisible)
		[editor resignFirstResponder];
}

-(void)kt_upArrow:(id)sender
{
	[self.richEditor upArrow];
}

-(void)kt_downArrow:(id)sender
{
	[self.richEditor downArrow];
}

-(void)kt_leftArrow:(id)sender
{
	[self.richEditor leftArrow];
}

-(void)kt_rightArrow:(id)sender
{
	[self.richEditor rightArrow];
}

#pragma mark - meat & potatoes

-(void)reloadFileData
{
	[self.fileController reloadData];
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
	return self.richEditor.text;
}

-(BOOL)isFileLoaded
{
	return self.currentFile && !self.currentFile.readOnlyValue;
}

-(void)updateDocumentState
{
	self.executeButton.enabled = self.richEditor.attributedText.length > 0;
	self.richEditor.editable = self.isFileLoaded;
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
	self.syntaxParser=nil;
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

-(void)saveFileData:(BasicBlock1IntArg)completion
{
	if (!OSAtomicCompareAndSwap32(0, 1, &_syncInProgress)) {
		//sync already in progress
		completion(YES);
		return;
	}
	UIView *rootView = self.view.superview;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
	hud.labelText = @"Saving…";
	self.currentFile.localEdits = self.richEditor.text;
	[[Rc2Server sharedInstance] saveFile:self.currentFile
							 toContainer:_session.workspace
					   completionHandler:^(BOOL success, id results)
	 {
		 [MBProgressHUD hideHUDForView:rootView animated:YES];
		 if (!OSAtomicCompareAndSwap32(1, 0, &_syncInProgress))
			 Rc2LogError(@"unlocking sync lock failed");
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
		 if (completion)
			 completion(success);
	 }];
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
	[self dismissViewControllerAnimated:YES completion:nil];
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

	//restore last directory used
	NSString *lastPath = [[NSUserDefaults standardUserDefaults] objectForKey:kLastDropBoxPathPref];
	if (lastPath.length > 1) {
		lastPath = [lastPath substringFromIndex:1]; //cut off first slash
		NSMutableString *buildPath = [NSMutableString string];
		for (NSString *pathC in [lastPath componentsSeparatedByString:@"/"]) {
			if ([pathC length] < 1)
				break;
			[buildPath appendFormat:@"/%@", pathC];
			DropboxImportController *aDc = [[DropboxImportController alloc] init];
			aDc.session = _session;
			aDc.dropboxCache = self.dropboxCache;
			aDc.thePath = buildPath;
			[self.importController pushViewController:aDc animated:NO];
		}
	}
	
	CGSize sz = self.importController.view.frame.size;
	[self presentViewController:self.importController animated:YES completion:nil];
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
	self.richEditor.editable = !limited && self.isFileLoaded;
}

-(void)executeBlockAfterSave:(BasicBlock)block
{
	if (self.currentFile.locallyModified)
		[self saveFileData:^(NSInteger x) {
			block();
		}];
	else
		block();
}

-(void)promptForNewFile:(BOOL)shared
{
	self.currentAlert = [[UIAlertView alloc] initWithTitle:(shared?@"New shared file name":@"New file name:") message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	__weak EditorViewController *blockSelf=self;
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
		RCFile *file = [RCFile MR_createEntity];
		file.name = str;
		file.localEdits = @"";
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

-(void)internalExecute:(RCSessionExecuteOptions)options
{
	if ([self.currentFile.name hasSuffix:@".sas"]) {
		[self executeBlockAfterSave:^{ [self.session executeSas:self.currentFile]; }];
	} else {
		[self executeBlockAfterSave:^{
			[_session executeScriptFile:self.currentFile options:options];
		}];
	}
}

-(void)userWillAdjustWidth
{
	self.widthAdjustTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES usingBlock:^(NSTimer *timer) {
		[self adjustLineNumbers];
	}];
}

-(void)userDidAdjustWidth
{
	[self.widthAdjustTimer invalidate];
	[self adjustLineNumbers];
}

-(void)presentFileExport:(RCFile*)file
{
	if (![[DBSession sharedSession] isLinked]) {
		Rc2AppDelegate *del = (Rc2AppDelegate*)TheApp.delegate;
		__weak EditorViewController *bself = self;
		del.dropboxCompletionBlock = ^{
			[bself presentFileExport:file];
		};
		[[DBSession sharedSession] linkFromController:self.view.window.rootViewController];
		return;
	}
	DropboxFolderSelectController *dbc = [[DropboxFolderSelectController alloc] init];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:dbc];
	__weak UIViewController *blockVC = nc;
	dbc.doneButtonTitle = @"Select";
	dbc.dropboxCache = [[NSMutableDictionary alloc] init];
	dbc.navigationItem.title = @"Select Destination:";
	dbc.doneHandler = ^(DropboxFolderSelectController *controller, NSString *thePath) {
		[blockVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
		[self uploadFile:file toPath:thePath existingRevision:[controller revisiionIdForFile:file.name]];
	};
	nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[nc setValue:[NSValue valueWithCGSize:CGSizeMake(400, 450)] forKey:@"formSheetSize"];
	[self presentViewController:nc animated:YES completion:nil];
}

-(void)uploadFile:(RCFile*)file toPath:(NSString*)dbPath existingRevision:(NSString*)revisionId
{
	if (Nil == file || nil == dbPath)
		return;
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window.rootViewController.view animated:YES];
	if (file.fileSize.integerValue > 1024 * 10)
		hud.mode = MBProgressHUDModeDeterminate;
	else
		hud.mode = MBProgressHUDModeIndeterminate;
	hud.labelText = [NSString stringWithFormat:@"uploading %@ to Dropbox", file.name];
	[DropBlocks uploadFile:file.name toPath:dbPath withParentRev:revisionId fromPath:file.fileContentsPath completionBlock:^(NSString *unknownString, DBMetadata *metadata, NSError *error)
	{
		[hud hide:YES];
	} progressBlock:^(CGFloat progress) {
		hud.progress = progress;
	}];
	[hud show:YES];
}

#pragma mark - actions

-(IBAction)doExecute:(id)sender
{
	[self internalExecute:RCSessionExecuteOptionNone];
}

-(void)loadFile:(RCFile*)file
{
	[self loadFile:file showProgress:YES];	
}

-(void)loadFile:(RCFile*)file showProgress:(BOOL)showProgress
{
	if (self.syncInProgress) {
		//this can happen if a workspacefileupdated message comes via the websocket before our REST call to save the file returns.
		Rc2LogWarn(@"loadFile called while save in progress");
		return;
	}

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
	self.richEditor.attributedText = [[NSAttributedString alloc] initWithString:@""];
	self.currentFile=nil;
	[self updateDocumentState];
}

-(IBAction)doActivityPopover:(id)sender
{
	if (self.filePopover.isPopoverVisible) {
		[self.filePopover dismissPopoverAnimated:YES];
	}
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
		[items addObject:self.richEditor.text];
	DrropboxUploadActivity *dbactivity = [[DrropboxUploadActivity alloc] init];
	dbactivity.filesToUpload = @[file];
	dbactivity.performBlock = ^{
		[self presentFileExport:file];
	};
	[activs addObject:dbactivity];
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

-(IBAction)doRenameFile:(id)sender
{
	self.currentAlert = [[UIAlertView alloc] initWithTitle:@"Rename file to:" message:@"" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil];
	self.currentAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[self.currentAlert textFieldAtIndex:0].text = self.currentFile.name;
	__weak EditorViewController *blockSelf=self;
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
	[self saveFileData:nil];
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
		[[DBSession sharedSession] linkFromController:self.view.window.rootViewController];
	}
}

-(IBAction)doShowFiles:(id)sender
{
	if (self.filePopover.popoverVisible) {
		[self.filePopover dismissPopoverAnimated: YES];
		return;
	}
	if (self.activityPopover.isPopoverVisible) {
		[self.activityPopover dismissPopoverAnimated:YES];
		self.activityPopover = nil;
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

- (void)richTextChanged:(NSNotification*)note
{
	[self updateTextContents:nil];
}

-(void)updateTextContents:(NSAttributedString*)srcStr
{
	if (nil == self.syntaxParser)
		self.syntaxParser = [RCSyntaxParser parserWithTextStorage:self.richEditor.textStorage fileType:self.currentFile.fileType];
	if (![srcStr.string isEqualToString:self.richEditor.attributedText.string])
		[self.richEditor.textStorage setAttributedString:srcStr];
	[self.richEditor.textStorage addAttributes:self.defaultTextAttrs range:NSMakeRange(0, srcStr.length)];
	[self.keyboardToolbar switchToPanelForFileExtension:self.currentFile.name.pathExtension];
}

-(void)scrollSelectionVisible:(BOOL)animate
{
    CGRect caretRect = [self.richEditor caretRectForPosition:self.richEditor.selectedTextRange.end];
	CGRect visibleRect = self.richEditor.frame;
	visibleRect.size.height -= self.richEditor.contentInset.bottom;
	visibleRect.origin.y = self.richEditor.contentOffset.y;

	CGPoint offset = self.richEditor.contentOffset;
	CGFloat croppedHeight = CGRectGetHeight(self.richEditor.bounds) - self.richEditor.contentInset.bottom;
	offset.y = caretRect.origin.y - croppedHeight;
	if (offset.y < 0) offset.y = 0;
	if (!CGRectContainsRect(visibleRect, caretRect))
		[self.richEditor setContentOffset:offset animated:YES];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	[self scrollSelectionVisible:YES];
	return YES;
}
- (void)textViewDidChange:(UITextView *)tview
{
	[self updateDocumentState];
	[self scrollSelectionVisible:NO];
}

- (void)textViewDidChangeSelection:(UITextView *)tview
{
	[self scrollSelectionVisible:NO];
}

#pragma mark - text storage delegate

-(void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
	
}

-(void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
	if (self.isParsing)
		return;
	//only parse if last parse was longer than .5 seconds ago
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (now - self.lastParseTime > .5) {
		self.lastParseTime = now;
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!self.isParsing) {
				self.isParsing = YES;
				[self.syntaxParser parse];
				self.isParsing = NO;
			}
		});
	}
}

#pragma mark - accessors

-(void)setSession:(RCSession*)sess
{
	_session = sess;
	__weak EditorViewController *blockSelf = self;
	[self observeTarget:sess keyPath:@"restrictedMode" options:0 block:^(MAKVONotification *notification) {
		[blockSelf sessionModeChanged];
		//only show in classroom mode if not the master
		blockSelf.handButton.hidden = !blockSelf.session.isClassroomMode || [blockSelf.session currentUser].master;
	}];
	[self observeTarget:sess keyPath:@"handRaised" options:0 block:^(MAKVONotification *notification) {
		blockSelf.handButton.selected = blockSelf.session.handRaised;
	}];
}

@end
