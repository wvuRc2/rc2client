//
//  WorkspaceCellView.h
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <AppKit/AppKit.h>

@class RCWorkspace;
@class WorkspaceCellView;

@protocol WorkspaceCellViewDelegate <NSObject>
-(void)workspaceCell:(WorkspaceCellView*)cellView addDetail:(id)sender;
-(void)workspaceCell:(WorkspaceCellView*)cellView removeDetail:(id)sender;
-(void)workspaceCell:(WorkspaceCellView*)cellView doubleClick:(id)sender;
-(void)workspaceCell:(WorkspaceCellView *)cellView setExpanded:(BOOL)expanded;
-(void)workspaceCell:(WorkspaceCellView *)cellView handleDroppedFiles:(NSArray*)files replaceExisting:(BOOL)replace;
@end

//object value must be set before workspace
@interface WorkspaceCellView : NSTableCellView<NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, weak) NSTableView *parentTableView;
@property (nonatomic, strong) IBOutlet NSTableView *detailTableView;
@property (nonatomic, strong) RCWorkspace *workspace;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL detailItemSelected;
@property (nonatomic, retain, readonly) id selectedObject;
@property (nonatomic, readonly) NSMutableArray *contentArray;
@property (nonatomic, unsafe_unretained) id<WorkspaceCellViewDelegate> cellDelegate;
@property (nonatomic) BOOL acceptsFileDragAndDrop;

-(CGFloat)expandedHeight;

-(void)reloadData;

-(IBAction)addDetailItem:(id)sender;
-(IBAction)removeDetailItem:(id)sender;
-(IBAction)doubleClick:(id)sender;
@end
