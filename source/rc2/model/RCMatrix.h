//
//  RCMatrix.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/22/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import "RCVariable.h"

@interface RCMatrix : RCVariable
@property (nonatomic, readonly) NSInteger rowCount;
@property (nonatomic, readonly) NSInteger colCount;

-(NSString*)valueAtRow:(int)row column:(int)col;
@end
