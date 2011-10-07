//
//  SessionWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "SessionWindowController.h"
#import "MacSessionViewController.h"
#import "AppDelegate.h"
#import "RCSession.h"
#import "RCWorkspace.h"

@implementation SessionWindowController

-(id)initWithViewController:(MacSessionViewController*)svc
{
	if ((self = [super initWithWindowNibName:@"SessionWindowController"])) {
		self.viewController = svc;
	}
	
	return self;
}

-(void)windowWillClose:(NSNotification *)note
{
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	[appDel closeSessionViewController:self.viewController];
	[appDel removeWindowController:self];
}

-(void)windowDidLoad
{
	[super windowDidLoad];
	AppDelegate *appDel = (AppDelegate*)[NSApp delegate];
	[appDel addWindowController:self];
	self.viewController.view.frame = self.theView.bounds;
	[self.theView addSubview:self.viewController.view];
	self.window.title = [NSString stringWithFormat:@"Session: %@", self.viewController.session.workspace.name];
	[self.window setContentBorderThickness:24 forEdge:NSMinYEdge];
}

@synthesize viewController;
@synthesize theView;
@end
