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
	self.mainWindowController = [[LogViewWindowController alloc] init];
	[self.mainWindowController.window makeKeyAndOrderFront:self];
}

@synthesize mainWindowController;
@end
