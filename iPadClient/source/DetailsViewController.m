//
//  DetailsViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "DetailsViewController.h"
#import "Rc2Server.h"
#import "RCWorkspace.h"
#import "RCFile.h"
#import "Rc2AppDelegate.h"
#import "FileDetailsCell.h"
#import "MessageController.h"
#import "ThemeEngine.h"
#import "AppConstants.h"

#define kDefaultTitleText @"Welcome to Rc²"

enum {
	eWelcomeVisible=0,
	eMessagesVisible,
	eWorkspaceVisible
};

@interface DetailsViewController() {
	NSInteger _whatsVisible;
	NSTimeInterval _lastTapTime;
	BOOL _didMsgCheck;
	BOOL _didNibCheck;
}
@property (nonatomic, strong) NSMutableArray *rc2Tokens;
@property (nonatomic, strong) NSString *wspaceFilesToken;
@property (nonatomic, strong) RCWorkspace *selectedWorkspace;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) MessageController *messageController;
@property (nonatomic, strong) UIView *currentView;
@property (nonatomic, strong) NSIndexPath *selectedIndex;
-(void)updateSelectedWorkspace:(RCWorkspace*)wspace;
-(void)updateSelectedWorkspace:(RCWorkspace*)wspace withLogout:(BOOL)doLogout;
-(void)updateLoginStatus;
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
	[super freeUpMemory];
	self.dateFormatter=nil;
	self.dateFormatter=nil;
	for (id aToken in self.rc2Tokens)
		[[Rc2Server sharedInstance] removeObserverWithBlockToken:aToken];
	self.rc2Tokens=nil;
    self.workspaceContent=nil;
    self.welcomeContent=nil;
	self.actionSheet=nil;
}

-(void)dealloc
{
	[self freeUpMemory];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	if (!_didNibCheck) {
		self.rc2Tokens = [NSMutableArray array];
		self.dateFormatter = [[NSDateFormatter alloc] init];
		[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		__block __weak DetailsViewController *blockSelf = self;
		id aToken = [[Rc2Server sharedInstance] addObserverForKeyPath:@"selectedWorkspace" 
																		   task:^(id obj, NSDictionary *change)
		{
			RCWorkspace *sel = [obj selectedWorkspace];
				[blockSelf updateSelectedWorkspace:sel];
		}];
		[self.rc2Tokens addObject:aToken];
		self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		aToken =  [[Rc2Server sharedInstance] addObserverForKeyPath:@"loggedIn" 
																		   task:^(id obj, NSDictionary *change) {
			   [blockSelf performSelectorOnMainThread:@selector(updateLoginStatus) withObject:nil waitUntilDone:NO];
		}];
		[self.rc2Tokens addObject:aToken];
		self.loginButton.possibleTitles = [NSSet setWithObjects:@"Login",@"Logout",nil];
		self.loginButton.title = @"Login";
		self.fileTableView.rowHeight = 52;
		self.fileTableView.allowsSelection = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileTableDoubleTapped:) name:kTableViewDoubleClickedNotification object:self.fileTableView];
		self.currentView = self.welcomeContent;
		_didNibCheck=YES;
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	[self freeUpMemory];
	self.fileTableView.allowsSelection = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kTableViewDoubleClickedNotification object:nil];
	_didMsgCheck = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)ior
{
	return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	if (self.currentView == self.welcomeContent)
		self.workspaceContent.frame = self.currentView.frame;
	else
		self.welcomeContent.frame = self.currentView.frame;
}

#pragma mark - actions
/*
-(IBAction)doActionMenu:(id)sender
{
	if (self.isettingsPopover) {
		//alraady displauing it, so dimiss it
		[self.isettingsPopover dismissPopoverAnimated:YES];
		self.isettingsPopover=nil;
		return;
	}
	if (nil == self.isettingsController) {
		self.isettingsController = [[iSettingsController alloc] init];
		self.isettingsController.contentSizeForViewInPopover = CGSizeMake(350, 340);
	}
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.isettingsController];
	self.isettingsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
	[self.isettingsPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	self.isettingsController.containingPopover = self.isettingsPopover;
}*/

-(IBAction)doStartSession:(id)sender
{
	Rc2AppDelegate *del = (Rc2AppDelegate*)[[UIApplication sharedApplication] delegate];
	RCFile *selFile=nil;
	if (self.selectedIndex)
		selFile = [self.selectedWorkspace.files objectAtIndex:self.selectedIndex.row];
	[del startSession:selFile];
}

-(IBAction)doMessages:(id)sender
{
	Theme *theme = [[ThemeEngine sharedInstance] currentTheme];
	if (nil == self.messageController) {
		self.messageController = [[MessageController alloc] init];
		self.messageController.view.frame = self.welcomeContent.frame;
		[self.messageController viewDidLoad];
		self.messageController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

	}
	[self updateMessageIcon:YES];
	if (self.currentView == self.messageController.view) {
		self.titleLabel.text = kDefaultTitleText;
		[UIView transitionFromView:self.messageController.view
							toView:self.welcomeContent
						  duration:0.7
						   options:UIViewAnimationOptionTransitionFlipFromRight
						completion:^(BOOL finished) { self.messageController=nil; }];
		self.currentView = self.welcomeContent;
		self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
		[Rc2Server sharedInstance].selectedWorkspace=nil;
	} else {
		self.titleLabel.text = @"Message Center";
		NSManagedObjectContext *moc = [TheApp valueForKeyPath:@"delegate.managedObjectContext"];
		self.messageController.messages = [moc fetchObjectsForEntityName:@"RCMessage" withPredicate:nil sortKey:@"dateSent"];
		[UIView transitionFromView:self.currentView
							toView:self.messageController.view
						  duration:0.7
						   options:UIViewAnimationOptionTransitionFlipFromLeft
						completion:^(BOOL finished) { }];
		self.currentView = self.messageController.view;
		self.view.backgroundColor = [theme colorForKey:@"MessageCenterBackground"];
	}
}

#pragma mark - meat & potatoes

-(void)fileTableDoubleTapped:(NSNotification*)note
{
//	[self doStartSession:nil];
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
	[self updateSelectedWorkspace:wspace withLogout:NO];
}

-(void)updateSelectedWorkspace:(RCWorkspace*)wspace withLogout:(BOOL)doLogout
{
	if (self.wspaceFilesToken) {
		[self.selectedWorkspace removeObserverWithBlockToken:self.wspaceFilesToken];
		self.wspaceFilesToken=nil;
	}
	self.selectedWorkspace = wspace;
	__block __weak DetailsViewController *blockSelf = self;
	if (nil == wspace) {
		if (self.currentView == self.workspaceContent) {
			//need to switch back to welcome
			[UIView transitionFromView:self.workspaceContent
								toView:self.welcomeContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromRight
							completion:^(BOOL finished) { 
								//if (doLogout) [blockSelf doLoginLogout:nil]; 
							}];
			self.currentView = self.welcomeContent;
			self.titleLabel.text = kDefaultTitleText;
/*		} else {
			//they are must be in messages and we need to flip to a workspace
			[UIView transitionFromView:self.currentView
								toView:self.workspaceContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromRight
							completion:^(BOOL finished) { }];
			self.currentView = self.workspaceContent;
*/		}
	} else {
		self.titleLabel.text = wspace.name;
		if (self.currentView != self.workspaceContent) {
			[UIView transitionFromView:self.currentView
								toView:self.workspaceContent
							  duration:0.7
							   options:UIViewAnimationOptionTransitionFlipFromLeft
							completion:^(BOOL finished) {}];
			self.currentView = self.workspaceContent;
			self.workspaceContent.frame = self.welcomeContent.frame;
		}
		self.wspaceFilesToken = [wspace addObserverForKeyPath:@"files" 
														 task:^(id theWspace, NSDictionary *changes) {
			[blockSelf performSelectorOnMainThread:@selector(handleFileUpdate:) withObject:theWspace waitUntilDone:NO];
		}];
		[wspace refreshFiles];
	}
	[self updateMessageIcon:NO];
	self.sessionButton.enabled = self.currentView == self.workspaceContent;
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

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.welcomeContent.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.workspaceContent.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	if(self.currentView == self.welcomeContent)
	   self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	else
		self.view.backgroundColor = [theme colorForKey:@"MessageCenterBackground"];
	[self.view setNeedsDisplay];
}

-(void)updateMessageIcon:(BOOL)aboutToSwitch
{
	UIButton *theButton = (UIButton*)self.messagesButton.customView;
	if (![Rc2Server sharedInstance].loggedIn) {
		[theButton setImage:[UIImage imageNamed:@"message-tbar"] forState:UIControlStateNormal];
		[theButton setImage:[UIImage imageNamed:@"message-tbar-down"] forState:UIControlStateHighlighted];
	} else if (aboutToSwitch) {
		if (self.currentView == self.messageController.view) {
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
			[theButton setImage:[UIImage imageNamed:@"home-tbar"] forState:UIControlStateNormal];
			[theButton setImage:[UIImage imageNamed:@"home-tbar-down"] forState:UIControlStateHighlighted];
		}
	} else {
		if (self.currentView == self.messageController.view) {
			[theButton setImage:[UIImage imageNamed:@"home-tbar"] forState:UIControlStateNormal];
			[theButton setImage:[UIImage imageNamed:@"home-tbar-down"] forState:UIControlStateHighlighted];
		} else {
			[theButton setImage:[UIImage imageNamed:@"message-tbar"] forState:UIControlStateNormal];
			[theButton setImage:[UIImage imageNamed:@"message-tbar-down"] forState:UIControlStateHighlighted];
		}
	}
}

#pragma mark - Table view

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
	if ([indexPath isEqual:self.selectedIndex]) {
		if (self.selectedIndex && [NSDate timeIntervalSinceReferenceDate] - _lastTapTime < 0.4) {
			//count it as a double tap
			RCFile *selFile = [self.selectedWorkspace.files objectAtIndex:self.selectedIndex.row];
			if ([selFile.name hasSuffix:@".pdf"]) {
				[(Rc2AppDelegate*)TheApp.delegate displayPdfFile:selFile];
			} else {
				[self doStartSession:self];
			}
			return indexPath;
		}
		if (self.selectedIndex)
			[tableView deselectRowAtIndexPath:self.selectedIndex animated:YES];
		self.selectedIndex=nil;
	} else
		self.selectedIndex = indexPath;
	_lastTapTime = [NSDate timeIntervalSinceReferenceDate];
	return self.selectedIndex;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 75.0;
}

#pragma mark - synthesizers

@synthesize dateFormatter;
@synthesize titleLabel;
@synthesize wspaceFilesToken;
@synthesize loginButton;
@synthesize sessionButton;
@synthesize fileTableView;
@synthesize workspaceContent;
@synthesize welcomeContent;
@synthesize actionSheet;
@synthesize messageController;
@synthesize currentView;
@synthesize rc2Tokens;
@synthesize selectedIndex;
@end
