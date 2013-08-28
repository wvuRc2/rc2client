//
//  FunctionVariableSummaryCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/17/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCVariable;

@interface FunctionVariableSummaryCell : UITableViewCell
@property (nonatomic, weak) RCVariable *variable;
@property (nonatomic) NSInteger customRowHeight;

-(void)updateFonts;
@end
