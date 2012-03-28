//
//  RCMUserAdminController.h
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import "MacClientAbstractViewController.h"

@interface RCMUserAdminController : MacClientAbstractViewController<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, strong) IBOutlet NSTableView *resultsTable;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;
@property (nonatomic, strong) IBOutlet NSArrayController *userController;
@property (nonatomic, strong) IBOutlet NSArrayController *detailController;
@property (nonatomic) BOOL searchesNames;
@property (nonatomic) BOOL searchesLogins;
@property (nonatomic) BOOL searchesEmails;

-(IBAction)searchUsers:(id)sender;
-(IBAction)addUser:(id)sender;
-(IBAction)toggleSearchFilter:(id)sender;
-(IBAction)dismissAddUser:(id)sender;
@end
