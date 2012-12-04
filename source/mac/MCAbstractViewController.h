//
//  MCAbstractViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCAbstractViewController : AMViewController
@property (nonatomic,getter=isBusy) BOOL busy;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, readonly) NSView *rightStatusView;
@end
