//
//  MacMainViewController.h
//  MacClient
//
//  Created by Mark Lilback on 10/14/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"
#import "PXSourceList.h"

@class RCWorkspace;

@interface MacMainViewController : MacClientAbstractViewController<PXSourceListDataSource,PXSourceListDelegate>
@property (strong) IBOutlet PXSourceList *mainSourceList;
@property (strong, nonatomic) IBOutlet AMControlledView *detailView;
@property (strong, nonatomic) IBOutlet AMControlledView *detailContainer;
@property (strong, nonatomic) MacClientAbstractViewController *detailController;
@property (strong) IBOutlet NSMenu *wsheetContextMenu;
@property (strong) IBOutlet NSMenu *wsheetFolderContextMenu;
@property (readonly) RCWorkspace *selectedWorkspace; //not KVO compliant

-(IBAction)doRenameWorksheetFolder:(id)sender;
-(IBAction)doOpenSession:(id)sender;
-(IBAction)doOpenSessionInNewWindow:(id)sender;
-(IBAction)doAddWorkspace:(id)sender;
-(IBAction)doAddWorkspaceFolder:(id)sender;

@end
