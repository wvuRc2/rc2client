//
//  SessionEditorProtocol.h
//  iPadClient
//
//  Created by Mark Lilback on 6/5/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SessionEditor <NSObject>

@property (nonatomic, copy) NSString *string;
@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic, assign) BOOL inputAccessoryVisible;

@property (nonatomic, copy) void (^helpBlock)(id<SessionEditor> editView);
@property (nonatomic, copy) void (^executeBlock)(id<SessionEditor> editView);
@property (nonatomic, strong) UIView *inputAccessoryView;
@property (nonatomic, assign) NSRange selectedRange;
@property (readonly) BOOL isEditorFirstResponder;
@property (nonatomic, assign) BOOL editable;

@property (readonly) UIView *view;

-(void)upArrow;
-(void)downArrow;
-(void)leftArrow;
-(void)rightArrow;

-(void)resignFirstResponder;
-(void)becomeFirstResponder;

-(void)setDefaultFontName:(NSString*)fontName size:(CGFloat)fontSize;
@end
