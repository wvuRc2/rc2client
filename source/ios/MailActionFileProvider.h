//
//  MailActionFileProvider.h
//  Rc2Client
//
//  Created by Mark Lilback on 10/15/14.
//  Copyright (c) 2014 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;

@interface MailActionFileProvider : UIActivityItemProvider
@property (nonatomic, strong) RCFile *file;
-(instancetype)initWithRCFile:(RCFile*)file;
@end
