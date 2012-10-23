//
//  SpreadsheetCell.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpreadsheetCell : UIView
@property (nonatomic, copy) NSString *content;
@property (nonatomic) BOOL isHeader;
@end
