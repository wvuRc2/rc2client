//
//  SendMessageViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 6/7/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "SendMessageViewController.h"
#import "Rc2Server.h"
#import "Vyana-ios/AMNavigationTreeController.h"
#import "JSTokenField.h"
#import "JSTokenButton.h"

@interface SendMessageViewController () <UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,JSTokenFieldDelegate,UIPopoverControllerDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITableViewCell *toCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *subjectCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *bodyCell;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UITextField *subjectField;
@property (nonatomic, strong) IBOutlet JSTokenField *toField;
@property (nonatomic, strong) IBOutlet UIButton *addRcptButton;
@property (nonatomic, strong) AMNavigationTreeController *rcptController;
@property (nonatomic, strong) UIPopoverController *rcptPopover;
@property (nonatomic, copy) NSArray *availableRcpts;
@end

@implementation SendMessageViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.subjectField.text = @"";
	self.bodyTextView.text = @"";
	self.sendButton.enabled = NO;
	self.toField.delegate = self;
	self.toField.label.text = @"To:";
	self.toField.textField.enabled=NO;
	UITapGestureRecognizer *tapg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toFieldTapped:)];
	tapg.numberOfTapsRequired = 1;
	[self.toField addGestureRecognizer:tapg];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toFieldResized:) name:JSTokenFieldFrameDidChangeNotification object:self.toField];
	NSMutableArray *rcpts = [[[Rc2Server sharedInstance] messageRecipients] mutableCopy];
	[rcpts addObjectsFromArray:[Rc2Server sharedInstance].classesTaught];
	self.availableRcpts = rcpts;
	if ([rcpts count] == 1) {
		[self.toField addTokenWithTitle:[rcpts.firstObject objectForKey:@"name"] representedObject:rcpts.firstObject];
		self.addRcptButton.hidden=YES;
	} else {
		//need to use a popup
		AMNavigationTreeController *tc = [[AMNavigationTreeController alloc] init];
		self.rcptController = tc;
		tc.contentItems = rcpts;
		tc.keyForCellText = @"name";
		tc.delegate = (id)self;
		tc.contentSizeForViewInPopover = CGSizeMake(300, 250);
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:JSTokenFieldFrameDidChangeNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - meat & potatos

-(void)navTree:(AMNavigationTreeController*)navTree leafItemTouched:(id)item
{
	[self.rcptPopover dismissPopoverAnimated:YES];
	self.rcptPopover=nil;
	[self.toField addTokenWithTitle:[item valueForKey:@"name"] representedObject:item];
}

-(void)toFieldResized:(NSNotification*)note
{
	[self.tableView reloadRowsAtIndexPaths:ARRAY([NSIndexPath indexPathForRow:0 inSection:0]) withRowAnimation:UITableViewRowAnimationNone];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	self.rcptPopover=nil;
}

#pragma mark - actions

-(IBAction)showRcptsPopup:(id)sender
{
	if (self.rcptPopover) {
		[self.rcptPopover dismissPopoverAnimated:YES];
		self.rcptPopover=nil;
		return;
	}
	NSMutableArray *avail = [self.availableRcpts mutableCopy];
	[avail removeObjectsInArray:[self.toField valueForKeyPath:@"tokens.representedObject"]];
	self.rcptController.contentItems = avail;
	self.rcptPopover = [[UIPopoverController alloc] initWithContentViewController:self.rcptController];
	self.rcptPopover.delegate = self;
	[self.rcptPopover presentPopoverFromRect:self.addRcptButton.frame inView:self.toCell 
					permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
}

-(void)toFieldTapped:(UIGestureRecognizer*)grecog
{
	if (nil == self.rcptController)
		return;
	id deepView = [self.toField hitTest:[grecog locationInView:self.toField] withEvent:nil];
	if ([deepView isKindOfClass:[JSTokenButton class]]) {
		[self.toField removeTokenForString:[[deepView representedObject] valueForKey:@"name"]];
		return;
	}
}

-(IBAction)cancel:(id)sender
{
	self.completionBlock(NO);
}

-(IBAction)send:(id)sender
{
	__block SystemSoundID soundId;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"mailsent" withExtension:@"caf"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundId);
		
	});
	AudioServicesPlaySystemSound(soundId);
	NSLog(@"sound should've played");
	self.completionBlock(YES);
}

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 3;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row) {
		case 0:
			return self.toCell;
		case 1:
			return self.subjectCell;
		case 2:
			return self.bodyCell;
	}
	Rc2LogError(@"invalid table row asked for in %@", NSStringFromClass([self class]));
	return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 2) {
		return self.tableView.bounds.size.height - 98;
	}
	if (indexPath.row == 0) {
		return self.toField.frame.size.height + 13;
	}
	return 44;
}

#pragma mark - text editing

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.subjectField) {
		[self.bodyTextView becomeFirstResponder];
		return NO;
	}
	return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
	self.sendButton.enabled = textView.text.length > 0 && self.subjectField.text.length > 0;
}

#pragma mark - synthesizers

@synthesize tableView=_tableView;
@synthesize bodyCell=_bodyCell;
@synthesize subjectCell=_subjectCell;
@synthesize sendButton=_sendButton;
@synthesize toCell=_toCell;
@synthesize bodyTextView=_bodyTextView;
@synthesize toField=_toField;
@synthesize subjectField=_subjectField;
@synthesize completionBlock=_completionBlock;
@synthesize rcptController=_rcptController;
@synthesize rcptPopover=_rcptPopover;
@synthesize addRcptButton=_addRcptButton;
@synthesize availableRcpts=_availableRcpts;
@end
