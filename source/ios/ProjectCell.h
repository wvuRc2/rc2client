//
//  ProjectCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCProject;

@interface ProjectCell : UICollectionViewCell
@property (nonatomic, strong) RCProject *project;
@end
