//
//  SendMessageViewController.h
//  iPadClient
//
//  Created by Mark Lilback on 6/7/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendMessageViewController : UIViewController
@property (nonatomic, copy) BasicBlock1IntArg completionBlock; //BOOL success
@property (nonatomic, copy) NSArray *priorityImages;
@end
