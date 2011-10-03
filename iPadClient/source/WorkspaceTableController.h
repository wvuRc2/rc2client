//
//  WorkspaceTableController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCWorkspaceItem;

@interface WorkspaceTableController : UITableViewController
@property (nonatomic, retain) RCWorkspaceItem *parentItem;
@property (nonatomic, copy) NSArray *workspaceItems;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *addButton;
- (IBAction)doAdd:(id)sender;
-(void)clearSelection;
@end
