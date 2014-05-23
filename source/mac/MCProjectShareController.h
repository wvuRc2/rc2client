//
//  MCProjectShareController.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/22/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCProject;

@interface MCProjectShareController : AMViewController
@property (nonatomic, strong) RCProject *project;
@end
