//
//  MacMainWindowController.h
//  MacClient
//
//  Created by Mark Lilback on 9/12/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PXSourceList.h"

@interface MacMainWindowController : NSWindowController<NSWindowDelegate,PXSourceListDataSource,PXSourceListDelegate>
@property (strong) IBOutlet PXSourceList *mainSourceList;
@property (strong, nonatomic) IBOutlet NSView *detailView;
@property (strong) IBOutlet NSScrollView *detailContainer;
@property (strong) IBOutlet NSMenu *wsheetContextMenu;
@property (strong) IBOutlet NSMenu *wsheetFolderContextMenu;
@property (strong) IBOutlet NSPopUpButton *addPopup;
@property (nonatomic) BOOL canAdd;

-(IBAction)doRenameWorksheetFolder:(id)sender;
-(IBAction)doOpenSession:(id)sender;
-(IBAction)doOpenSessionInNewWindow:(id)sender;
-(IBAction)doAddWorkspace:(id)sender;
-(IBAction)doAddWorkspaceFolder:(id)sender;
@end
