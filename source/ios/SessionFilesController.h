//
//  SessionFilesController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;
@class RCSession;

@interface SessionFilesController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) IBOutlet AMTableView *tableView;
@property (nonatomic, unsafe_unretained) id delegate;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

-(id)initWithSession:(RCSession*)session;

-(void)reloadData;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doDropboxImport:(id)sender;
@end

@protocol SessionFilesDelegate <NSObject>
-(void)loadFile:(RCFile*)file;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doNewSharedFile:(id)sender;
-(IBAction)presentDropboxImport:(id)sender;
-(void)dismissSessionsFilesController;
@end