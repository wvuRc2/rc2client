//
//  RCMTextPrintView.h
//  MacClient
//
//  Created by Mark Lilback on 12/19/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCMTextPrintView : NSView
@property (nonatomic, copy) NSAttributedString *textContent;
@property (nonatomic, copy) NSString *jobName;
@end
