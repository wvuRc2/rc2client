//
//  DetailsViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "DetailsViewController.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "Rc2AppDelegate.h"
#import "FileDetailsCell.h"
#import "SettingsController.h"
#import "MessageController.h"
#import "ThemeEngine.h"

#define kDefaultTitleText @"Welcome to Rc²"

enum {
	eWelcomeVisible=0,
	eMessagesVisible,
	eWorkspaceVisible
};

@interface DetailsViewController() {
	NSInteger _whatsVisible;
	BOOL _didMsgCheck;
}
@property (nonatomic, retain) NSString *selWspaceToken;
@property (nonatomic, retain) NSString *loggedInToken;
@property (nonatomic, retain) NSString *wspaceFilesToken;
@property (nonatomic, retain) RCWorkspace *selectedWorkspace;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) SettingsController *settingsController;
@property (nonatomic, retain) MessageController *messageController;
@property (nonatomic, assign) UIView *currentView;
-(void)updateSelectedWorkspace:(RCWorkspace*)wspace;
-(void)updateSelectedWorkspace:(RCWorkspace*)wspace withLogout:(BOOL)doLogout;
-(void)updateLoginStatus;
-(void)displaySettings;
-(void)updateMessageIcon:(BOOL)aboutToSwitch;
-(void)cleanupAfterLogout;
-(void)postLoginSetup;
@end

@implementation DetailsViewController
@synthesize selectedWorkspace=_selectedWorkspace;

#pragma mark - init/alloc

- (id)init
{
	self = [super initWithNibName:@"DetailsViewController" bundle:nil];
	return self;
}

-(void)freeUpMemory
{
	self.settingsController=nil;
	self.dateFormatter=nil;
	self.dateFormatter=nil;
	if (self.selWspaceToken)
		[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.selWspaceToken];
	if (self.loggedInToken)
		[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.loggedInToken];
	self.selWspaceToken=nil;
	self.loggedInToken=nil;
    self.workspaceContent=nil;
    self.welcomeContent=nil;
	self.wsLoginButton=nil;
	self.actionSheet=nil;
	self.messageNavView=nil;
}

-(void)dealloc
{
	[self freeUpMemory];
	[super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	__block DetailsViewController *blockSelf = self;
	self.selWspaceToken = [[Rc2Server sharedInstance] addObserverForKeyPath:@"selectedWorkspace" 
																	   task:^(id obj, NSDictionary *change) {
		RCWorkspace *sel = [obj selectedWorkspace];
	   if (blockSelf.selectedWorkspace != sel) {
			[blockSelf updateSelectedWorkspace:sel];
//		   [blockSelf performSelectorOnMainThread:@selector(updateSelectedWorkspace:) withObject:sel waitUntilDone:NO];
	   }
	}];
	self.loggedInToken =  [[Rc2Server sharedInstance] addObserverForKeyPath:@"loggedIn" 
																	   task:^(id obj, NSDictionary *change) {
		   [blockSelf performSelectorOnMainThread:@selector(updateLoginStatus) withObject:nil waitUntilDone:NO];
	}];
	self.loginButton.possibleTitles = [NSSet setWithObjects:@"Login",@"Logout",nil];
	self.loginButton.title = @"Login";
	self.fileTableView.rowHeight = 52;
	self.currentView = self.welcomeContent;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	[self freeUpMemory];
	[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.selWspaceToken];
	[[Rc2Server sharedInstance] removeObserverWithBlockToken:self.loggedInToken];
	self.fileTableView.allowsSelection = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
	return UIInterfaceOrientationIsLandscape(ior);;
}

#pragma mark - actions

-(IBAction)doActionMenu:(id)sender
{
	if (nil == self.actionSheet) {
		self.actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Settings",nil] autorelease];
	}
	[self.actionSheet showFromBarButtonItem:sender animated:YES];	
}

-(IBAction)doStartSession:(id)sender
{
	Rc2AppDelegate *del = [[UIApplication sharedApplication] delegate];
	[del startSession];
}

-(IBAction)doLogoutFromWSPage:(id)sender
{
	[self updateSelectedWorkspace:nil withLogout:YES];
}

-(IBAction)doLoginLogout:(id)sender
{
	if ([Rc2Server sharedInstance].loggedIn) {
		[[Rc2Server sharedInstance] logout];
	} else {
		Rc2AppDelegate *del = [[UIApplication sharedApplication] delegate];
		[del promptForLogin];
	}
}

-(IBAction)doMessages:(id)sender
{
	Theme *theme = [ThemeEngine currentTheme];
	if (nil == self.messageController) {
		self.messageController = [[[MessageController alloc] init] autorelease];
		self.messageController.view.frame = self.welcomeContent.frame;
		[self.messageController viewDidLoad];
	}
	[self updateMessageIcon:YES];
	if (nil == self.welcomeContent.superview) {
		self.titleLabel.text = kDefaultTitleText;
		[UIView transitionFromView:self.messageController.view
							toView:self.welcomeContent
						  duration:0.7
						   options:UIViewAnimationOptionTransitionFlipFromRight
						completion:^(BOOL finished) { }];
		self.currentView = self.welcomeContent;
		self.view.backgroundColor = [UIColor whiteColor];
	} else {
		self.titleLabel.text = @"Message Center";
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		self.messageController.messages = [moc fetchObjectsForEntityName:@"RCMessage" withPredicate:nil sortKey:@"dateSent"];
		[UIView transitionFromView:self.welcomeContent
							toView:self.messageController.view
						  duration:0.7
						   options:UIViewAnimationOptionTransitionFlipFromLeft
						completion:^(BOOL finished) { }];
		self.currentView = self.messageController.view;
		self.view.backgroundColor = [theme colorForKey:@"MessageCenterBackground"];
	}
}

#pragma mark - meat & potatoes

-(void)displaySettings
{
	if (nil == self.settingsController) {
		SettingsController *fc = [[SettingsController alloc] init];
		self.settingsController = fc;
		[fc release];
	}
	self.settingsController.modalPresentationStyle = UIModalPresentationPageSheet;
	[self.settingsController view];
	CGSize sz = self.settingsController.view.frame.size;
	[self presentModalViewController:self.settingsController animated:YES];
	self.settingsController.view.superview.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
	| UIViewAutoresizingFlexibleBottomMargin;
	CGRect r = self.settingsController.view.superview.frame;
	r.size = sz;
	self.settingsController.view.superview.frame = r;
	CGPoint centerPt = CGPointZero;
	centerPt.x = 512;
	centerPt.y = 100 + floor(sz.height/2);
	self.settingsController.view.superview.center = centerPt;
}

-(void)refreshDetails
{
	[self.fileTableView reloadData];
}

-(void)postLoginSetup
{
	self.messagesButton.enabled=YES;
	[self updateMessageIcon:NO];
}

-(void)cleanupAfterLogout
{
	self.selectedWorkspace=nil;
	[self.fileTableView reloadData];
	if (nil == self.welcomeContent.superview)
		[self doMessages:self];
	[self.fileTableView reloadData];
	[self updateMessageIcon:NO];
	self.sessionButton.enabled = NO;
	self.messagesButton.enabled = NO;
	self.messageController=nil;
}

//called via KVO when Rc2Server.loggedIn is changed
-(void)updateLoginStatus
{
	if ([Rc2Server sharedInstance].loggedIn) {
		self.loginButton.title = @"Logout";
		[self postLoginSetup];
	} else {
		self.loginButton.title = @"Login";
		[self cleanupAfterLogout];
	}
	if (!_didMsgCheck) {
		[[Rc2Server sharedInstance] syncMessages:^(BOOL success, id results) {
			//this likely a duplicate call, but it is necessary if there are new messages
			[self updateMessageIcon:NO];
		}];
		_didMsgCheck=YES;
	}
}

-(void)handleFileUpdate:(RCWorkspace*)wspace
{
	ZAssert(wspace == self.selectedWorkspace, @"got file callback for non-selected workspace");
	[self.fileTableView reloadData];
}

//this is called when the workspace changes via KVO, i.e. the user touched one in the master view
-(void)updateSelectedWorkspace:(RCWorkspace*)wspace
{
	//for now, we'll ignore that they selected a workspace
	if (self.currentView != self.messageController.view)
		[self updateSelectedWorkspace:wspace withLogout:NO];
}

-(void)updateSelectedWorkspace:(RCWorkspace*)wspace withLogout:(BOOL)doLogout
{
	if (self.wspaceFilesToken) {
		[self.selectedWorkspace removeObserverWithBlockToken:self.wspaceFilesToken];
		self.wspaceFilesToken=nil;
	}
	self.selectedWorkspace = wspace;
	__block DetailsViewController *blockSelf = self;
	if (nil == wspace) {
		if (self.currentView == self.workspaceContent) {
			//need to switch back to welcome
			[UIView transitionFromView:self.workspaceContent
								toView:self.welcomeContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromRight
							completion:^(BOOL finished) { if (doLogout) [blockSelf doLoginLogout:nil]; }];
			self.currentView = self.welcomeContent;
			self.titleLabel.text = kDefaultTitleText;
		} else {
			//they are must be in messages and we need to flip to a workspace
			[UIView transitionFromView:self.messageController.view
								toView:self.workspaceContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromRight
							completion:^(BOOL finished) { }];
			self.currentView = self.workspaceContent;
		}
	} else {
		self.wspaceLabel.text = wspace.name;
		if (self.currentView != self.workspaceContent) {
			[UIView transitionFromView:self.currentView
								toView:self.workspaceContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromLeft
							completion:^(BOOL finished) {}];
			self.currentView = self.workspaceContent;
		}
		self.wspaceFilesToken = [wspace addObserverForKeyPath:@"files" 
														 task:^(id theWspace, NSDictionary *changes) {
			[blockSelf performSelectorOnMainThread:@selector(handleFileUpdate:) withObject:theWspace waitUntilDone:NO];
		}];
		[wspace refreshFiles];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0)
		return; //canceled
	if (0 == buttonIndex) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self displaySettings];
		});
	}
}

-(UIImage*)editMessageImage:(UIImage*)origImage messageCount:(NSInteger)count
{
	UIGraphicsBeginImageContext(origImage.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[origImage drawAtPoint:CGPointZero];
	CGContextTranslateCTM(ctx, 0, origImage.size.height);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextSelectFont(ctx, "Helvetica-Bold", 10, kCGEncodingMacRoman);
	CGContextSetTextDrawingMode(ctx, kCGTextFillStroke);
	CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
	CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
	char str[48];
	sprintf(str, "%d", count);
	CGPoint pt = {30, 18};
	if (count > 9) {
		pt.x = 27;
		pt.y = 18;
	}
	CGContextShowTextAtPoint(ctx, pt.x, pt.y, str, strlen(str));
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

-(void)updateMessageIcon:(BOOL)aboutToSwitch
{
	UIButton *theButton = (UIButton*)self.messagesButton.customView;
	if (![Rc2Server sharedInstance].loggedIn) {
		[theButton setImage:[UIImage imageNamed:@"message-tbar"] forState:UIControlStateNormal];
		[theButton setImage:[UIImage imageNamed:@"message-tbar-down"] forState:UIControlStateHighlighted];
	} else if (!aboutToSwitch || (nil == self.welcomeContent.superview)) {
		//we are showing messages but about to change
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		NSInteger count = [moc countForEntityName:@"RCMessage" withPredicate:@"dateRead = nil"];
		if (count < 1) {
			[theButton setImage:[UIImage imageNamed:@"message-tbar"] forState:UIControlStateNormal];
			[theButton setImage:[UIImage imageNamed:@"message-tbar-down"] forState:UIControlStateHighlighted];
		} else {
			if (count > 100)
				count = 99;
			UIImage *img = [self editMessageImage:[UIImage imageNamed:@"message-tbar-badged"] messageCount:count];
			[theButton setImage:img forState:UIControlStateNormal];
			img = [self editMessageImage:[UIImage imageNamed:@"message-tbar-badged-down"] messageCount:count];
			[theButton setImage:img forState:UIControlStateHighlighted];
		}
	} else {
		//we are switching to message view
		[theButton setImage:[UIImage imageNamed:@"home-tbar"] forState:UIControlStateNormal];
		[theButton setImage:[UIImage imageNamed:@"home-tbar-down"] forState:UIControlStateHighlighted];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.selectedWorkspace.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	FileDetailsCell *cell = [FileDetailsCell cellForTableView:tableView];
	cell.dateFormatter = self.dateFormatter;

	RCFile *file = [self.selectedWorkspace.files objectAtIndex:indexPath.row];
	[cell showValuesForFile:file];
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 75.0;
}

#pragma mark - synthesizers

@synthesize dateFormatter;
@synthesize titleLabel;
@synthesize selWspaceToken;
@synthesize loggedInToken;
@synthesize wspaceFilesToken;
@synthesize loginButton;
@synthesize wsLoginButton;
@synthesize sessionButton;
@synthesize fileTableView;
@synthesize workspaceContent;
@synthesize welcomeContent;
@synthesize actionSheet;
@synthesize settingsController;
@synthesize msgCntLabel;
@synthesize messagesButton;
@synthesize messageNavView;
@synthesize messageController;
@synthesize currentView;
@synthesize wspaceLabel;
@end
