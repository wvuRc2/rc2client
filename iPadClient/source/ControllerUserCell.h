//
//  ControllerUserCell.h
//  iPadClient
//
//  Created by Mark Lilback on 2/17/12.
//  Copyright (c) 2012 Agile Monks. All rights reserved.
//

@class RCSessionUser;

@interface ControllerUserCell : iAMTableViewCell
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) RCSessionUser *user;
@end
