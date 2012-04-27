//
//  MessageController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

@interface MessageController : NSObject
-(id)init;

@property (nonatomic, strong) IBOutlet UIView *view;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, copy) NSArray *messages;
-(IBAction)doDone:(id)sender;
-(IBAction)doDeleteMessage:(id)sender;
-(void)viewDidLoad;
@end
