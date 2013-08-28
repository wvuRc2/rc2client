//
//  BasicVariableCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/16/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BasicVariableCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *valueLabel;

-(void)updateFonts;
@end
