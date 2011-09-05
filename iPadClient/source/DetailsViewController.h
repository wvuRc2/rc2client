//
//  DetailsViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/23/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (nonatomic, assign) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) IBOutlet UILabel *wspaceLabel;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *loginButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *wsLoginButton;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *sessionButton;
@property (nonatomic, assign) IBOutlet UITableView *fileTableView;
@property (nonatomic, assign) IBOutlet UILabel *msgCntLabel;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *messagesButton;
@property (retain, nonatomic) IBOutlet UIView *workspaceContent;
@property (retain, nonatomic) IBOutlet UIView *welcomeContent;
@property (retain, nonatomic) IBOutlet UIView *messageNavView;

-(IBAction)doLogoutFromWSPage:(id)sender;
-(IBAction)doLoginLogout:(id)sender;
-(IBAction)doStartSession:(id)sender;
-(IBAction)doActionMenu:(id)sender;
-(IBAction)doMessages:(id)sender;
-(void)refreshDetails;
@end
