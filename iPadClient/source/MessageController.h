//
//  MessageController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/4/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

@interface MessageController : NSObject
-(id)init;

@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, copy) NSArray *messages;
-(IBAction)doDone:(id)sender;
-(IBAction)doDeleteMessage:(id)sender;
-(void)viewDidLoad;
@end
