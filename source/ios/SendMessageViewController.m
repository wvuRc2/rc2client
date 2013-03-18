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
#import "RCCourse.h"
#import "RCUser.h"

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
@property (nonatomic, strong) IBOutlet UIButton *priorityImage;
@property (nonatomic, strong) AMNavigationTreeController *rcptController;
@property (nonatomic, strong) AMNavigationTreeController *priorityController;
@property (nonatomic, strong) UIPopoverController *currentPopover;
@property (nonatomic, strong) NSDictionary *selectedPriority;
@property (nonatomic, copy) NSArray *availableRcpts;
@end

#define NSNUM(x) [NSNumber numberWithInteger:x]

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
	NSArray *rcpts = [[Rc2Server sharedInstance] messageRecipients];
	NSArray *classes = [Rc2Server sharedInstance].classesTaught;
	if (classes) //classes first in order
		rcpts = [classes arrayByAddingObjectsFromArray:rcpts];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - meat & potatos

-(void)navTree:(AMNavigationTreeController*)navTree leafItemTouched:(id)item
{
	[self.currentPopover dismissPopoverAnimated:YES];
	self.currentPopover=nil;
	if (navTree == self.rcptController) {
		[self.toField addTokenWithTitle:[item valueForKey:@"name"] representedObject:item];
	} else if (navTree == self.priorityController) {
		[self.priorityImage setImage:[navTree.selectedItem objectForKey:@"img"] forState:UIControlStateNormal];
		self.selectedPriority = navTree.selectedItem;
	}
}

-(void)toFieldResized:(NSNotification*)note
{
	[self.tableView reloadRowsAtIndexPaths:ARRAY([NSIndexPath indexPathForRow:0 inSection:0]) withRowAnimation:UITableViewRowAnimationNone];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	self.currentPopover=nil;
}

#pragma mark - actions

-(IBAction)showPriorityPopup:(id)sender
{
	if (nil == self.priorityController) {
		AMNavigationTreeController *tc = [[AMNavigationTreeController alloc] init];
		self.priorityController = tc;
		NSArray *imgs = self.priorityImages;
		tc.contentItems = ARRAY(
			[NSDictionary dictionaryWithObjectsAndKeys:@"High", @"name", [imgs objectAtIndex:3], @"img", NSNUM(3), @"val", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Normal", @"name", [imgs objectAtIndex:2], @"img", NSNUM(2), @"val", nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Low", @"name", [imgs objectAtIndex:1], @"img", NSNUM(1), @"val", nil]
		);
		tc.keyForCellText = @"name";
		tc.keyForCellImage = @"img";
		tc.delegate = (id)self;
		tc.contentSizeForViewInPopover = CGSizeMake(160, 140);
	}
	self.currentPopover = [[UIPopoverController alloc] initWithContentViewController:self.priorityController];
	self.currentPopover.delegate = self;
	[self.currentPopover presentPopoverFromRect:self.priorityImage.frame inView:self.subjectCell
					   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];	
}

-(IBAction)showRcptsPopup:(id)sender
{
	if (self.currentPopover) {
		[self.currentPopover dismissPopoverAnimated:YES];
		self.currentPopover=nil;
		return;
	}
	NSMutableArray *avail = [self.availableRcpts mutableCopy];
	[avail removeObjectsInArray:[self.toField valueForKeyPath:@"tokens.representedObject"]];
	self.rcptController.contentItems = avail;
	self.currentPopover = [[UIPopoverController alloc] initWithContentViewController:self.rcptController];
	self.currentPopover.delegate = self;
	[self.currentPopover presentPopoverFromRect:self.addRcptButton.frame inView:self.toCell 
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
	if ([self.subjectField isFirstResponder])
		[self.subjectField resignFirstResponder];
	if ([self.bodyTextView isFirstResponder])
		[self.bodyTextView resignFirstResponder];
	NSMutableDictionary *msg = [[NSMutableDictionary alloc] init];
	[msg setObject:self.subjectField.text forKey:@"subject"];
	[msg setObject:self.bodyTextView.text forKey:@"body"];
	NSNumber *priority = [self.selectedPriority objectForKey:@"val"];
	if (nil == priority)
		priority = [NSNumber numberWithInt:2];
	[msg setObject:priority forKey:@"priority"];
	NSMutableArray *userRcpts = [NSMutableArray array];
	NSMutableArray *classRcpts = [NSMutableArray array];
	for (id rcpt in [self.toField valueForKeyPath:@"tokens.representedObject"]) {
		if ([rcpt isKindOfClass:[RCCourse class]])
			[classRcpts addObject:[rcpt courseId]];
		else
			[userRcpts addObject:[rcpt objectForKey:@"id"]];
	}
	[msg setObject:userRcpts forKey:@"userRcpts"];
	[msg setObject:classRcpts forKey:@"classRcpts"];
	//send the message
	[[Rc2Server sharedInstance] sendMessage:msg completionHandler:^(BOOL success, id results) {
		//FIXME: need to verify it was sent or report any error
		self.completionBlock(YES);
	}];
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
		return self.tableView.bounds.size.height - 54 - (self.toField.frame.size.height + 13);
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
@end
