//
//  AppDelegate.m
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "AppDelegate.h"
#import "LogViewWindowController.h"

@interface AppDelegate()
@property (nonatomic, retain) LogViewWindowController *mainWindowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self promptForLogin:nil];
}

-(IBAction)promptForLogin:(id)sender
{
	[self.loginWindow makeKeyAndOrderFront:self];
}

-(IBAction)doLogin:(id)sender
{
	[self.loginWindow orderOut:self];
	NSString *urlStr=nil, *sname=nil;
	switch (self.selectedServerIndex) {
		case 1:
			urlStr = @"ws://barney.stat.wvu.edu:8080/iR/al";
			sname = @"barney";
			break;
		case 2:
			urlStr = @"ws://localhost:8080/iR/al";
			sname = @"local";
			break;
		case 0:
		default:
			sname = @"Rc2";
			urlStr = @"ws://rc2.stat.wvu.edu:8080/iR/al";
			break;
	}
	self.mainWindowController = [[LogViewWindowController alloc] initWithServerName:sname urlString:urlStr];
	[self.mainWindowController.window makeKeyAndOrderFront:self];
}

@synthesize mainWindowController;
@synthesize loginWindow;
@synthesize selectedServerIndex;
@end
