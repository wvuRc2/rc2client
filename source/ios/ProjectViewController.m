//
//  ProjectViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ProjectViewController.h"
#import "ProjectCell.h"
#import "Rc2Server.h"
#import "ThemeEngine.h"
#import "ProjectViewLayout.h"
#import "RCProject.h"
#import "RCWorkspace.h"
#import "Rc2AppDelegate.h"
#import "MAKVONotificationCenter.h"
#import "ImageDisplayController.h"
#import "RCImage.h"

@interface ProjectViewController ()
@end

@implementation ProjectViewController

-(void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"Rc2 Projects", @"");

	ImageDisplayController *imgController = [[ImageDisplayController alloc] init];
	[imgController view]; //force loading
	/* debug code for working on image display
	NSString *ipath = [[NSBundle mainBundle] pathForResource:@"RDoc" ofType:@"png"];
	RCImage *img = [[RCImage alloc] initWithPath:ipath];
	imgController.allImages = @[img];
	[imgController loadImages];
	[imgController setImageDisplayCount:1];
	RunAfterDelay(1, ^{
		[self.navigationController pushViewController:imgController animated:YES];
	}); */
}

-(void)loginStatusChanged
{
	[super loginStatusChanged];
	self.navigationItem.title = NSLocalizedString(@"Rc2 Projects", @"");
}

@end
