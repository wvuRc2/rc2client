//
//  MCHelpSheetController.h
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/14.
//  Copyright 2014 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCHelpSheetController : NSWindowController
@property (nonatomic, copy) NSArray *helpItems;
@property (nonatomic, copy) void (^handler)(MCHelpSheetController *controller, NSDictionary *selItem);
@end
