//
//  SendMessageViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 6/7/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "SendMessageViewController.h"

@interface SendMessageViewController () <UITableViewDelegate,UITableViewDataSource,UITextViewDelegate,UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITableViewCell *toCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *subjectCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *bodyCell;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic, strong) IBOutlet UITextView *bodyTextView;
@property (nonatomic, strong) IBOutlet UITextField *subjectField;
@property (nonatomic, strong) IBOutlet UILabel *toLabel;
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

#pragma mark - actions

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
@synthesize toLabel=_toLabel;
@synthesize subjectField=_subjectField;
@synthesize completionBlock=_completionBlock;
@end
