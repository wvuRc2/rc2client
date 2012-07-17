//
//  NotificationCell.h
//  iPadClient
//
//  Created by Mark Lilback on 5/18/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationCell : iAMTableViewCell
@property (nonatomic, strong) NSDictionary *note;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end
