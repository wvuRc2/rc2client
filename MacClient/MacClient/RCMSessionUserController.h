//
//  RCMSessionUserController.h
//  MacClient
//
//  Created by Mark Lilback on 1/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCSession;

@interface RCMSessionUserController : AMViewController<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, strong) RCSession *session;
@property (nonatomic, strong) IBOutlet NSTableView *userTableView;
-(void)userJoined:(NSDictionary*)dict;
-(void)userLeft:(NSDictionary*)dict;
-(void)userListUpdated:(NSDictionary*)dict;

-(IBAction)refreshList:(id)sender;
@end
