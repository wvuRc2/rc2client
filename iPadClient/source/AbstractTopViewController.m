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

@interface AbstractTopViewController ()
@property (nonatomic, strong) UIPopoverController *isettingsPopover;
@property (nonatomic, strong) iSettingsController *isettingsController;
@property (nonatomic, strong) id themeChangeNotice;
@end

@implementation AbstractTopViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	self.kvoTokens = [NSMutableArray array];
	return self;
}

-(void)freeUpMemory
{
	[self.kvoTokens removeAllObjects];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	__unsafe_unretained AbstractTopViewController *blockSelf = self;
	id tn = [[ThemeEngine sharedInstance] registerThemeChangeBlock:^(Theme *theme) {
		[blockSelf updateForNewTheme:theme];
	}];
	self.themeChangeNotice = tn;
	[self updateForNewTheme:[[ThemeEngine sharedInstance] currentTheme]];
}

-(void)viewDidUnload
{
	[super viewDidUnload];
	self.themeChangeNotice=nil;
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
}

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
}

-(void)updateForNewTheme:(Theme*)theme
{
	
}

@synthesize isettingsPopover=_isettingsPopover;
@synthesize isettingsController=_isettingsController;
@synthesize messagesButton=_messagesButton;
@synthesize homeButton=_homeButton;
@synthesize kvoTokens=_kvoTokens;
@synthesize themeChangeNotice=_themeChangeNotice;
@end
