//
//  RCMAddShareController.h
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCWorkspace;
@class RCWorkspaceShare;

typedef void (^AddShareHandler)(NSNumber *userId);

@interface RCMAddShareController : AMViewController<NSTableViewDelegate,NSTableViewDataSource>
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) IBOutlet NSTableView *resultsTable;
@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, copy) AddShareHandler changeHandler;

-(IBAction)addShareForUser:(id)sender;
-(IBAction)performSearch:(id)sender;
@end
