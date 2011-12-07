//
//  WorkspaceViewController.h
//  MacClient
//
//  Created by Mark Lilback on 9/30/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"
#import "WorkspaceCellView.h"

@class RCWorkspace;
@class RCFile;

@interface WorkspaceViewController : MacClientAbstractViewController<WorkspaceCellViewDelegate>
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic, strong) IBOutlet NSTableView *sectionsTableView;
@property (nonatomic, strong) RCFile *selectedFile;

-(id)initWithWorkspace:(RCWorkspace*)aWorkspace;
-(IBAction)doRefreshFileList:(id)sender;

@end
