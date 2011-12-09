//
//  WorkspaceTableCell.h
//  iPadClient
//
//  Created by Mark Lilback on 8/24/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

@class RCWorkspaceItem;

@interface WorkspaceTableCell : iAMTableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) RCWorkspaceItem *item;
@property (nonatomic, assign) BOOL drawSelected;
@end
