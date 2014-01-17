//
//  MCUserAdminController.h
//  MacClient
//
//  Created by Mark Lilback on 10/28/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "MCAbstractViewController.h"

@interface MCUserAdminController : MCAbstractViewController<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic) BOOL searchesNames;
@property (nonatomic) BOOL searchesLogins;
@property (nonatomic) BOOL searchesEmails;

-(IBAction)searchUsers:(id)sender;
-(IBAction)addUser:(id)sender;
-(IBAction)toggleSearchFilter:(id)sender;
-(IBAction)dismissAddUser:(id)sender;
@end
