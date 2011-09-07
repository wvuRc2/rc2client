//
//  SettingsController.m
//  iPadClient
//
//  Created by Mark Lilback on 9/2/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "SettingsController.h"
#import "AppConstants.h"

static const CGFloat kKeyAnimationDuration = 0.3;
static const CGFloat kMinScrollFraction = 0.2;
static const CGFloat kMaxScrollFraction = 0.8;
static const CGFloat kKeyboardHeight = 354;


@interface SettingsController() {
	CGFloat _animationDistance;
}
@end

@implementation SettingsController

- (id)init
{
    self = [super initWithNibName:@"SettingsController" bundle:nil];
    if (self) {
    }
    return self;
}

-(void)freeUpMemory
{
	self.settingsTable=nil;
	self.leftyCell=nil;
	self.leftySwitch=nil;
	self.dynKeyCell=nil;
	self.dynKeyboardSwitch=nil;
	self.keyUrl1Field=nil;
	self.keyUrl2Field=nil;
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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
	[self setKeyUrl1Field:nil];
	[self setKeyUrl2Field:nil];
    [super viewDidUnload];
	[self freeUpMemory];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

-(void)viewWillAppear:(BOOL)animated
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.leftySwitch.on = [defaults boolForKey:kPrefLefty];
	self.dynKeyboardSwitch.on = [defaults boolForKey:kPrefDynKey];
	self.keyUrl1Field.text = [defaults objectForKey:kPrefCustomKey1URL];
	self.keyUrl2Field.text = [defaults objectForKey:kPrefCustomKey2URL];
}

#pragma mark - actions

-(IBAction)doClose:(id)sender
{
	if ([self respondsToSelector:@selector(presentingViewController)])
		[self.presentingViewController dismissModalViewControllerAnimated:YES];
	else
		[self.parentViewController dismissModalViewControllerAnimated:YES];
}

-(IBAction)valueChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (sender == self.leftySwitch || sender == self.dynKeyboardSwitch) {
		[defaults setBool:self.leftySwitch.on forKey:kPrefLefty];
		[defaults setBool:self.dynKeyboardSwitch.on forKey:kPrefDynKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:KeyboardPrefsChangedNotification 
															 object:[UIApplication sharedApplication].delegate];
	}
}

#pragma mark - text field

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	CGRect fldRectRelated = [self.view.window convertRect:textField.bounds fromView:textField];
	CGFloat fldbttm = fldRectRelated.origin.y + CGRectGetMaxY(textField.frame) + 8;
	if (fldbttm > kKeyboardHeight) {
		CGRect tfr = [self.view.window convertRect:textField.bounds fromView:textField];
		CGRect vr = [self.view.window convertRect:self.view.bounds fromView:self.view];
		CGFloat midline = tfr.origin.y + 0.5 * tfr.size.height;
		CGFloat numerator = midline - vr.origin.y - kMinScrollFraction * vr.size.height;
		CGFloat denominator = (kMaxScrollFraction - kMinScrollFraction) * vr.size.height;
		CGFloat heightFraction = numerator / denominator;
		if (heightFraction < 0.0)
			heightFraction = 0.0;
		if (heightFraction > 1.0)
			heightFraction = 1.0;
		_animationDistance = floor(kKeyboardHeight * heightFraction);
		CGRect viewFrame = self.view.frame;
		viewFrame.origin.y -= _animationDistance;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:kKeyAnimationDuration];
		self.view.frame = viewFrame;
		[UIView commitAnimations];
	} else {
		_animationDistance=0;
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	//store both of them
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (textField == self.keyUrl1Field)
		[defaults setObject:textField.text forKey:kPrefCustomKey1URL];
	else if (textField == self.keyUrl2Field)
		[defaults setObject:textField.text forKey:kPrefCustomKey2URL];
	if (_animationDistance > 0) {
		CGRect viewFrame = self.view.frame;
		viewFrame.origin.y += _animationDistance;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:kKeyAnimationDuration];
		self.view.frame = viewFrame;
		[UIView commitAnimations];
	}
}	

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.keyUrl1Field)
		[self.keyUrl2Field becomeFirstResponder];
	else
		[textField resignFirstResponder];
	return NO;
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0) 
		return self.leftyCell;
	return self.dynKeyCell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Settings";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 1)
		return 204;
	return 96;
}

#pragma mark - synthesizers

@synthesize settingsTable;
@synthesize leftyCell;
@synthesize leftySwitch;
@synthesize dynKeyboardSwitch;
@synthesize dynKeyCell;
@synthesize keyUrl1Field;
@synthesize keyUrl2Field;
@end
