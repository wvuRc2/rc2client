//
//  DetailsViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *loginButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sessionButton;
@property (nonatomic, strong) IBOutlet UITableView *fileTableView;
@property (nonatomic, strong) IBOutlet UILabel *msgCntLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *messagesButton;
@property (strong, nonatomic) IBOutlet UIView *workspaceContent;
@property (strong, nonatomic) IBOutlet UIView *welcomeContent;
@property (strong, nonatomic) IBOutlet UIView *messageNavView;

-(IBAction)doLogoutFromWSPage:(id)sender;
-(IBAction)doLoginLogout:(id)sender;
-(IBAction)doStartSession:(id)sender;
-(IBAction)doActionMenu:(id)sender;
-(IBAction)doMessages:(id)sender;
-(void)refreshDetails;
@end
