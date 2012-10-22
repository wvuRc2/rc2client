//
//  VariableSpreadsheetController.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCVariable;

@interface VariableSpreadsheetController : UIViewController
@property (nonatomic, strong) id variable; //must be RCMatrix or RCDataFrame
@end
