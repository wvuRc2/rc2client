//
//  SessionWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "SessionWindowController.h"
#import "SessionViewController.h"
#import "AppDelegate.h"
#import "RCSession.h"
#import "RCWorkspace.h"

@implementation SessionWindowController

-(id)initWithViewController:(SessionViewController*)svc
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
	self.window.contentView = self.viewController.view;
	self.window.title = [NSString stringWithFormat:@"Session: %@", self.viewController.session.workspace.name];
}

@synthesize viewController;
@end
