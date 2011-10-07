//
//  MacClientAbstractViewController.h
//  MacClient
//
//  Created by Mark Lilback on 10/7/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MacClientAbstractViewController : AMViewController
@property (nonatomic,getter=isBusy) BOOL busy;
@property (nonatomic, strong) NSString *statusMessage;
@end
