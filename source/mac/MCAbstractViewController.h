//
//  MCAbstractViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCAbstractViewController : AMViewController<NSToolbarDelegate>
@property (nonatomic,getter=isBusy) BOOL busy;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, readonly) NSView *rightStatusView;

//for subclasses to optionally override
-(void)didBecomeVisible;

//for toolbar, this class only sticks in a back button with identifier "back". subclasses need to overide delegate methods

//subclasses that use a toolbar should override this and return YES
-(BOOL)usesToolbar;

//convience for subclasses
-(NSToolbarItem*)toolbarButtonWithIdentifier:(NSString*)ident imgName:(NSString*)imgName width:(NSInteger)imgWidth;
@end
