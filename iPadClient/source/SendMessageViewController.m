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

@interface SendMessageViewController () <UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITableViewCell *toCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *subjectCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *bodyCell;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UITextField *subjectField;
@property (nonatomic, strong) IBOutlet UITextField *toField;
@property (nonatomic, strong) AMNavigationTreeController *rcptController;
@property (nonatomic, strong) UIPopoverController *rcptPopover;
@property (nonatomic, strong) NSMutableArray *selectedRcpts;
@end

@implementation SendMessageViewController

-(id)init
{
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
	}
	return self;
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.subjectField.text = @"";
	self.bodyTextView.text = @"";
	self.sendButton.enabled = NO;
	self.selectedRcpts = [[NSMutableArray alloc] init];
	NSArray *rcpts = [[Rc2Server sharedInstance] messageRecipients];
	if ([rcpts count] == 1) {
		self.toField.text = [rcpts.firstObject objectForKey:@"name"];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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
	self.toField.text = [item objectForKey:@"name"];
	[self.selectedRcpts addObject:item];
}

#pragma mark - actions

-(IBAction)popupRcpts:(id)sender
{
	if (self.rcptPopover) {
		[self.rcptPopover dismissPopoverAnimated:YES];
		self.rcptPopover=nil;
	} else {
		self.rcptPopover = [[UIPopoverController alloc] initWithContentViewController:self.rcptController];
		[self.rcptPopover presentPopoverFromRect:self.toField.frame inView:self.toCell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	if (textField == self.toField) {
		if (self.rcptController)
			[self popupRcpts:nil];
		return NO;
	}
	return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
	self.sendButton.enabled = textView.text.length > 0 && self.subjectField.text.length > 0;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	self.sendButton.enabled = self.bodyTextView.text.length > 0 && self.subjectField.text.length > 0;
	return YES;
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
@synthesize selectedRcpts=_selectedRcpts;
@end
