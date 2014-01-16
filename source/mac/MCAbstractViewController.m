//
//  MCAbstractViewController.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCAbstractViewController.h"
#import "MCMainWindowController.h"

@implementation MCAbstractViewController

-(void)setStatusMessage:(NSString *)statusMessage
{
	_statusMessage = [statusMessage copy];
	if (statusMessage) {
		RunAfterDelay(5, ^{
			if ([statusMessage isEqualToString:_statusMessage] && !self.busy)
				self.statusMessage=nil;
		});
	}
}

-(NSView*)rightStatusView
{
	return nil;
}

-(void)didBecomeVisible
{
	if ([self usesToolbar]) {
		NSToolbar *tbar = [[NSToolbar alloc] initWithIdentifier:@"maintbar"];
		tbar.delegate = self;
		tbar.displayMode = NSToolbarDisplayModeIconOnly;
		self.view.window.toolbar = tbar;
		self.view.window.toolbar.visible = YES;
	} else {
		self.view.window.toolbar.visible = NO;
	}
}

//subclasses that use a toolbar should override this and return YES
-(BOOL)usesToolbar
{
	return NO;
}

#pragma mark - toolbar delegate

-(NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"back"];
}

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"back"];
}

-(NSToolbarItem*)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item;
	if ([itemIdentifier isEqualToString:@"back"]) {
		item = [self toolbarButtonWithIdentifier:@"back" imgName:NSImageNameLeftFacingTriangleTemplate width:10];
		item.view.toolTip = @"Back";
		item.action = @selector(doBackToMainView:);
	}	return item;
}

-(AMMacToolbarItem*)toolbarButtonWithIdentifier:(NSString*)ident imgName:(NSString*)imgName width:(NSInteger)imgWidth
{
	NSImage *img = [NSImage imageNamed:imgName];
	if (imgWidth > 0) {
		img = [img copy];
		img.size = CGSizeMake(imgWidth, imgWidth);
	}
	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 29, 23)];
	button.image = img;
	//	[button setBordered:NO];
	[button setBezelStyle:NSTexturedRoundedBezelStyle];
	[button setButtonType:NSMomentaryChangeButton];
	AMMacToolbarItem *item = [[AMMacToolbarItem alloc] initWithItemIdentifier:ident];
	item.view = button;
	item.minSize = button.frame.size;
	return item;
}

@end
