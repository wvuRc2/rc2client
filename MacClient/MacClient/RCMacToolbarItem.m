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
@synthesize actionMenu=__actionMenu;
@synthesize menuStack;

-(void)imageSetup
{
	NSImage *timg = self.image;
	__didImgResize = YES;
	if (timg) {
		[timg setSize:NSMakeSize(12, 12)];
		NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(24, 24)];
		[img lockFocus];
		[timg drawInRect:NSMakeRect(6, 6, 16, 16) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[img unlockFocus];
		[img setTemplate:YES];
		[self setImage:img];
	}
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if (!__didImgResize)
		[self imageSetup];
}

-(void)setActionMenu:(NSMenu *)actionMenu
{
	__actionMenu = actionMenu;
	if (actionMenu) {
		self.target = self;
		self.action = @selector(myAction:);
		self.menuStack = [NSMutableArray array];
	}
}

-(void)setImage:(NSImage *)image
{
	[super setImage:image];
	if (!__didImgResize)
		[self imageSetup];
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
	} else if ([self.view respondsToSelector:@selector(setEnabled:)]) {
		//we have a custom view that can be enabled/disabled. figure out what our target is.
		BOOL enabled=NO;
		id target = self.target;
		if (nil == target || target == self) {
			id curResponder = self.view.window.firstResponder;
			while (curResponder) {
				if ([curResponder respondsToSelector:self.action] && 
					[curResponder respondsToSelector:@selector(validateUserInterfaceItem:)])
				{
					enabled = [curResponder validateUserInterfaceItem:self];
					break;
				}
				curResponder = [curResponder nextResponder];
			}
		} else if ([target respondsToSelector:@selector(validateUserInterfaceItem:)]) {
			enabled = [target validateUserInterfaceItem:self];
		}
		[(id)self.view setEnabled:enabled];
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

@end
