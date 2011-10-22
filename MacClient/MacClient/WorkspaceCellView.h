//
//  WorkspaceCellView.h
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <AppKit/AppKit.h>

@class RCWorkspace;

@interface WorkspaceCellView : NSTableCellView<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, weak) NSTableView *parentTableView;
@property (nonatomic, strong) IBOutlet NSTableView *detailTableView;
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL detailItemSelected;

-(IBAction)addDetailItem:(id)sender;
-(IBAction)removeDetailItem:(id)sender;
@end
