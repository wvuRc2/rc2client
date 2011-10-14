//
//  RCMacToolbarItem.h
//  MacClient
//
//  Created by Mark Lilback on 10/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//This subclass resizes the images to be 16x16 in a 24x24 space.
// It also allows an action menu to be specified to be displayed when clicked. this overrides the target/action.
// ViewControllers (or whatever) can push/pop their own menus.

@interface RCMacToolbarItem : NSToolbarItem<NSMenuDelegate>
@property (nonatomic, strong) IBOutlet NSMenu *actionMenu;

//so different views can push/pop their menus on a stack
-(void)pushActionMenu:(NSMenu*)menu;
-(void)popActionMenu:(NSMenu*)menu; //only pops if same menu as top of stack
@end
