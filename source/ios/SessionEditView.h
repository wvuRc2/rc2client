//
//  SessionEditView.h
//  Rc2Client
//
//  Created by Mark Lilback on 5/7/12.
//  Copyright 2012 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SessionEditView : UITextView
-(IBAction)showHelp:(id)sender;

@property (nonatomic, copy) void (^helpBlock)(SessionEditView *editView);
@property (nonatomic, copy) void (^executeBlock)(SessionEditView *editView);
@property (nonatomic, assign) NSRange selectedRange;
@property (readonly) BOOL isEditorFirstResponder;

@property (readonly) UIView *view;

-(void)upArrow;
-(void)downArrow;
-(void)leftArrow;
-(void)rightArrow;

@end
