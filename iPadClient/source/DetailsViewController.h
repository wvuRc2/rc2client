//
//  DetailsViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "AbstractTopViewController.h"

@interface DetailsViewController : AbstractTopViewController<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *loginButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sessionButton;
@property (nonatomic, strong) IBOutlet UITableView *fileTableView;
@property (strong, nonatomic) IBOutlet UIView *workspaceContent;
@property (strong, nonatomic) IBOutlet UIView *welcomeContent;

-(IBAction)doStartSession:(id)sender;
-(IBAction)doMessages:(id)sender;
-(void)refreshDetails;
@end
