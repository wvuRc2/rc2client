//
//  SessionWindowController.m
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMSessionWindowController.h"
#import "MacSessionViewController.h"
#import "AppDelegate.h"
#import "RCMAppConstants.h"
#import "RCSession.h"
#import "RCWorkspace.h"

@implementation RCMSessionWindowController

-(id)initWithViewController:(MacSessionViewController*)svc
{
	if ((self = [super initWithWindowNibName:@"RCMSessionWindowController"])) {
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
	NSToolbar *tbar = [[NSToolbar alloc] initWithIdentifier:@"sessionwindow"];
	[tbar setAllowsUserCustomization:NO];
	[tbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[tbar setSizeMode:NSToolbarSizeModeSmall];
	tbar.delegate = appDel;
	self.window.toolbar = tbar;
	NSInteger idx = [tbar.items indexOfObjectWithValue:RCMToolbarItem_Back usingSelector:@selector(itemIdentifier)];
	[tbar removeItemAtIndex:idx];
}

@synthesize viewController;
@synthesize theView;
@end
