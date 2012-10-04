//
//  RCMTextView.h
//  MacClient
//
//  Created by Mark Lilback on 10/16/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol RCMTextViewDelegate <NSTextViewDelegate>
-(void)handleTextViewPrint:(id)sender;
-(void)recolorText;
@end

@interface RCMTextView : NSTextView
@property (nonatomic, copy) NSDictionary *textAttributes;
@property (nonatomic, readonly) BOOL wordWrapEnabled;

-(IBAction)toggleWordWrap:(id)sender;
@end
