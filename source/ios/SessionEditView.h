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
//this is required because the UIKeyboardWillShowNotification is posted in the middle of becomeFirstResponder,
// leaving no way for someone listening to that notification to know if this view will be the first responder.
@property (readonly) BOOL isBecomingFirstResponder;

@property (readonly) UIView *view;

-(void)upArrow;
-(void)downArrow;
-(void)leftArrow;
-(void)rightArrow;

@end
