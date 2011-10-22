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
@property (nonatomic, readonly) NSMutableArray *contentArray;
//the argument will be the workspacecellview
@property (nonatomic, copy) BasicBlock1Arg addDetailHander;
@property (nonatomic, copy) BasicBlock1Arg removeDetailHander;

-(CGFloat)expandedHeight;

-(IBAction)addDetailItem:(id)sender;
-(IBAction)removeDetailItem:(id)sender;
@end
