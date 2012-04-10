//
//  RCMTextView.h
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol RCMTextViewDelegate <NSTextViewDelegate>
-(void)handleTextViewPrint:(id)sender;
@end

@interface RCMTextView : NSTextView
@property (nonatomic, copy) NSDictionary *textAttributes;
@end
