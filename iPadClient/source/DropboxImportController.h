//
//  DropboxImportController.h
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropboxImportController : UIViewController
@property (nonatomic, strong) IBOutlet UITableView *fileTable;
@property (nonatomic, copy) NSString *thePath;
@property (nonatomic, strong) NSMutableDictionary *dropboxCache;
@end
