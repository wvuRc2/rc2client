//
//  ThemeColorCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 3/13/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ThemeColorEntry;

@interface ColorView : UIView
@property (nonatomic, strong) UIColor *color;
@end

@interface ThemeColorCell : UITableViewCell
@property (strong) IBOutlet UILabel *nameLabel;
@property (strong) IBOutlet ColorView *colorView;
@property (nonatomic, weak) ThemeColorEntry *colorEntry;
@end
