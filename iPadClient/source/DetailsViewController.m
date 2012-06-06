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
	BOOL _didNibCheck;
}
@property (nonatomic, strong) NSMutableArray *rc2Tokens;
@property (nonatomic, copy) NSArray *files;
@property (nonatomic, strong) NSString *wspaceFilesToken;
@property (nonatomic, strong) RCWorkspace *selectedWorkspace;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIView *currentView;
@property (nonatomic, strong) NSIndexPath *selectedIndex;
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
	self.files = [self.selectedWorkspace.files sortedArrayUsingComparator:^(RCFile *file1, RCFile *file2) {
		return [file1.name compare:file2.name];
	}];
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

-(IBAction)doStartSession:(id)sender
{
	Rc2AppDelegate *del = (Rc2AppDelegate*)[[UIApplication sharedApplication] delegate];
	RCFile *selFile=nil;
	if (self.selectedIndex)
		selFile = [self.files objectAtIndex:self.selectedIndex.row];
	[del startSession:selFile];
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
}

-(void)cleanupAfterLogout
{
	self.selectedWorkspace=nil;
	[self.fileTableView reloadData];
	[self.fileTableView reloadData];
	self.sessionButton.enabled = NO;
	self.messagesButton.enabled = NO;
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
}

-(void)handleFileUpdate:(RCWorkspace*)wspace
{
	ZAssert(wspace == self.selectedWorkspace, @"got file callback for non-selected workspace");
	self.files = [wspace.files sortedArrayUsingComparator:^(RCFile *file1, RCFile *file2) {
		return [file1.name compare:file2.name];
	}];
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
	self.files = [wspace.files sortedArrayUsingComparator:^(RCFile *file1, RCFile *file2) {
		return [file1.name compare:file2.name];
	}];
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
		}
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
	}
	self.sessionButton.enabled = self.currentView == self.workspaceContent;
}

-(void)updateForNewTheme:(Theme*)theme
{
	[super updateForNewTheme:theme];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.welcomeContent.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.workspaceContent.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	self.view.backgroundColor = [theme colorForKey:@"WelcomeBackground"];
	[self.view setNeedsDisplay];
}


#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	FileDetailsCell *cell = [FileDetailsCell cellForTableView:tableView];
	cell.dateFormatter = self.dateFormatter;

	RCFile *file = [self.files objectAtIndex:indexPath.row];
	[cell showValuesForFile:file];
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath isEqual:self.selectedIndex]) {
		if (self.selectedIndex && [NSDate timeIntervalSinceReferenceDate] - _lastTapTime < 0.4) {
			//count it as a double tap
			RCFile *selFile = [self.files objectAtIndex:self.selectedIndex.row];
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
@synthesize currentView;
@synthesize rc2Tokens;
@synthesize selectedIndex;
@synthesize files=_files;
@end
