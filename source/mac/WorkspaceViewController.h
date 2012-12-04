//
//  WorkspaceViewController.h
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCAbstractViewController.h"
#import "WorkspaceCellView.h"

@class RCWorkspace;
@class RCFile;

@interface WorkspaceViewController : MCAbstractViewController<WorkspaceCellViewDelegate,NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic, strong) IBOutlet NSTableView *sectionsTableView;
@property (nonatomic, strong) RCFile *selectedFile;

-(id)initWithWorkspace:(RCWorkspace*)aWorkspace;
-(IBAction)doRefreshFileList:(id)sender;
-(IBAction)exportFile:(id)sender;
-(IBAction)importFile:(id)sender;

@end
