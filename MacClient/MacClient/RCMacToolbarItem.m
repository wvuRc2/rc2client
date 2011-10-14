//
//  RCMacToolbarItem.m
//  MacClient
//
//  Created by Mark Lilback on 10/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "RCMacToolbarItem.h"

@interface RCMacToolbarItem() {
	BOOL __didImgResize;
}
@property (nonatomic, strong) NSMutableArray *menuStack;
-(IBAction)myAction:(id)sender;
@end

@implementation RCMacToolbarItem
-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didImgResize) {
		NSImage *timg = self.image;
		if (timg) {
			[timg setSize:NSMakeSize(12, 12)];
			NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(24, 24)];
			[img lockFocus];
			[timg drawInRect:NSMakeRect(6, 6, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
			[img unlockFocus];
			[img setTemplate:YES];
			[self setImage:img];
		}
		if (self.actionMenu) {
			self.target = self;
			self.action = @selector(myAction:);
			self.menuStack = [NSMutableArray array];
		}
		__didImgResize = YES;
	}
}

-(void)pushActionMenu:(NSMenu*)menu
{
	[self.menuStack addObject:menu];
}

-(void)popActionMenu:(NSMenu*)menu
{
	if (menu == [self.menuStack lastObject])
		[self.menuStack removeLastObject];
}

-(void)validate
{
	if ([self.menuStack count] > 0) {
		NSMenu *menu = [self.menuStack lastObject];
		BOOL good=[menu.itemArray count] > 0;
		[menu update];
		for (NSMenuItem *mi in menu.itemArray) {
			if (!mi.isEnabled)
				good=NO;
		}
		[self setEnabled:good];
	} else {
		[super validate];
	}
}

-(IBAction)myAction:(id)sender
{
	NSView *v = [self valueForKey:@"_view"];
	NSMenu *menu = self.actionMenu;
	if (self.menuStack.count > 0)
		menu = [self.menuStack lastObject];
	[NSMenu popUpContextMenu:menu withEvent:[NSApp currentEvent] forView:v withFont:[NSFont systemFontOfSize:11]];
}

@synthesize actionMenu;
@synthesize menuStack;
@end
