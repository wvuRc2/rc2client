//
//  SessionFilesController.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;

@interface SessionFilesController : UIViewController 
@property (nonatomic, assign) IBOutlet AMTableView *tableView;
@property (nonatomic, assign) id delegate;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

-(void)reloadData;
-(IBAction)doNewFile:(id)sender;
-(IBAction)doDropboxImport:(id)sender;
@end

@protocol SessionFilesDelegate <NSObject>
-(void)loadFile:(RCFile*)file;
-(IBAction)doNewFile:(id)sender;
-(IBAction)presentDropboxImport:(id)sender;
-(void)dismissSessionsFilesController;
@end