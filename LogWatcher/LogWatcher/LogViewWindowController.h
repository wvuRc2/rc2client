//
//  LogViewWindowController.h
//  LogWatcher
//
//  Created by Mark Lilback on 9/24/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebSocket00.h"

@interface LogViewWindowController : NSWindowController<WebSocket00Delegate,NSWindowDelegate,NSMenuDelegate>
@property (nonatomic, strong) IBOutlet NSTableView *logTable;
@property (nonatomic, strong) IBOutlet NSArrayController *msgController;
@property (nonatomic, strong) NSNumber *levelSearch;
@property (nonatomic, strong) NSNumber *contextSearch;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) BOOL isLiveFeedMode;
@property (nonatomic, assign) BOOL useStartDate;
@property (nonatomic, assign) BOOL useEndDate;

-(id)initWithServerName:(NSString*)serverName urlString:(NSString*)serverUrl;
-(void)startWebSocket;
- (IBAction)doSearch:(id)sender;
- (IBAction)doLiveFeed:(id)sender;

@end
