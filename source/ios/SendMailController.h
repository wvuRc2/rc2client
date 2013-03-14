//
//  SendMailController.h
//  Rc2Client
//
//  Created by Mark Lilback on 3/14/13.
//  Copyright 2013 West Virginia University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SendMailController : NSObject
@property (readonly) MFMailComposeViewController *composer;
@property (copy) BasicBlock onSuccess;
@end
