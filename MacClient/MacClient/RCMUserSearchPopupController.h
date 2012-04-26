//
//  RCMUserSearchPopupController.h
//  MacClient
//
//  Created by Mark Lilback on 10/22/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^SelectUserHandler)(NSNumber *userId);
typedef BOOL (^ShowUserInResults)(NSNumber *userId);

@interface RCMUserSearchPopupController : AMViewController<NSTableViewDelegate,NSTableViewDataSource>
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) IBOutlet NSTableView *resultsTable;
@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, copy) SelectUserHandler selectUserHandler;
@property (nonatomic, copy) ShowUserInResults showUserHandler;
@property (nonatomic, copy) NSString *searchType;
@property (nonatomic, assign) BOOL removeSelectedUserFromList;

-(IBAction)selectUser:(id)sender;
-(IBAction)performSearch:(id)sender;
@end
