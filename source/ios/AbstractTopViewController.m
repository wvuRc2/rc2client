//
//  AbstractTopViewController.m
//  iPadClient
//
//  Created by Mark Lilback on 5/11/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "AbstractTopViewController.h"
#import "iSettingsController.h"
#import "ThemeEngine.h"
#import "Rc2Server.h"

@interface AbstractTopViewController ()
@property (nonatomic, strong) UIPopoverController *isettingsPopover;
@property (nonatomic, strong) iSettingsController *isettingsController;
@property (nonatomic, copy, readwrite) NSArray *standardLeftNavBarItems;
@property (nonatomic, copy, readwrite) NSArray *standardRightNavBarItems;
@end

@implementation AbstractTopViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MessagesUpdatedNotification object:nil];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	__weak AbstractTopViewController *blockSelf = self;
	[[ThemeEngine sharedInstance] registerThemeChangeObserver:self block:^(Theme *theme) {
		[blockSelf updateForNewTheme:theme];
	}];
	[self updateForNewTheme:[[ThemeEngine sharedInstance] currentTheme]];
	[self observeTarget:[Rc2Server sharedInstance] keyPath:@"loggedIn" selector:@selector(adjustInterfaceBasedOnLogin) userInfo:nil options:0];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messagesUpdated:) name:MessagesUpdatedNotification object:nil];
	[self adjustInterfaceBasedOnLogin];

	self.standardLeftNavBarItems = [(id)[TheApp delegate] standardLeftNavBarItems];
	self.standardRightNavBarItems = [(id)[TheApp delegate] standardRightNavBarItems];
}


-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	UIButton *theButton = (UIButton*)self.messagesButton.customView;
	[theButton setImage:[UIImage imageNamed:@"message-tbar"] forState:UIControlStateNormal];
	[theButton setImage:[UIImage imageNamed:@"message-tbar-down"] forState:UIControlStateHighlighted];
	theButton = (UIButton*)self.homeButton.customView;
	[theButton setImage:[UIImage imageNamed:@"home-tbar"] forState:UIControlStateNormal];
	[theButton setImage:[UIImage imageNamed:@"home-tbar-down"] forState:UIControlStateHighlighted];
	[self checkConstraints];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self checkConstraints]; //would prefer to happen in viewWillAppear, but just in case it didn't (which can happen)
}

-(void)checkConstraints
{
	if (self.view.superview && self.view.constraints.count < 2) {
		UIView *view = self.view;
		id topbar = self.topLayoutGuide;
		NSDictionary *vd = NSDictionaryOfVariableBindings(view, topbar);
		[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view]-0-|" options:0 metrics:nil views:vd]];
		[view.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[view]-0-|" options:0 metrics:nil views:vd]];
	}
}

-(IBAction)showProjects:(id)sender
{
	
}

-(IBAction)showMessages:(id)sender
{
	
}

-(IBAction)showGearMenu:(id)sender
{
	if (self.isettingsPopover) {
		//alraady displauing it, so dimiss it
		[self.isettingsPopover dismissPopoverAnimated:YES];
		self.isettingsPopover=nil;
		return;
	}
	if (nil == self.isettingsController) {
		self.isettingsController = [[iSettingsController alloc] init];
		self.isettingsController.contentSizeForViewInPopover = CGSizeMake(350, 500);
	}
	self.isettingsController.currentWorkspace = [self workspaceForSettings];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.isettingsController];
	self.isettingsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
	[self.isettingsPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	self.isettingsController.containingPopover = self.isettingsPopover;
}

-(void)adjustInterfaceBasedOnLogin
{
	if (self.gradingButton) {
		NSMutableArray *ma = [self.toolbar.items mutableCopy];
		NSArray *classes = [[Rc2Server sharedInstance] classesTaught];
		if ([classes count] > 0) {
			if (![ma containsObject:self.gradingButton]) {
				[ma insertObject:self.gradingButton atIndex:[ma count] - 4];
			}
		} else {
			[ma removeObject:self.gradingButton];
		}
		[self.toolbar setItems:ma animated:YES];
	}
}

-(void)updateForNewTheme:(Theme*)theme
{
	
}

///called when settings are to be displayed to get workspace to show settings for. Defaults to nil.
-(RCWorkspace*)workspaceForSettings
{
	return nil;
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

-(void)messagesUpdated:(NSNotification*)note
{
	UIButton *theButton = (UIButton*)self.messagesButton.customView;
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
}
@end
