//
//  WorkspaceCellView.h
//  MacClient
//
//  Created by Mark Lilback on 10/21/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface WorkspaceCellView : NSTableCellView
@property (nonatomic, weak) NSTableView *tableView;
@property (nonatomic) BOOL expanded;
@end
