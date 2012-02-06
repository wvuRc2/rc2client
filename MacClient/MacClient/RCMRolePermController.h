//
//  RCMRolePermController.h
//  MacClient
//
//  Created by Mark Lilback on 2/6/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMRolePermController : AMViewController
@property (nonatomic, strong) IBOutlet NSArrayController *permController;
@property (nonatomic, strong) IBOutlet NSTableView *permTable;
@property (nonatomic, strong) IBOutlet NSArrayController *roleController;
@property (nonatomic, strong) IBOutlet NSTableView *roleTable;
@property (nonatomic, strong) IBOutlet NSArrayController *rolePermController;
@end
