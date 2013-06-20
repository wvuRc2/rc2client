//
//  DropboxSyncSettingController.h
//  Rc2Client
//
//  Created by Mark Lilback on 6/20/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCWorkspace;

@interface DropboxSyncSettingController : UITableViewController
@property (nonatomic, weak) RCWorkspace *workspace;
@property (nonatomic, copy) NSString *thePath;
@property (nonatomic, strong) NSMutableDictionary *dropboxCache;
@end
