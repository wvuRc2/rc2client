//
//  ImageHolderView.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

@protocol ImageHolderViewDelegate;
@class RCImage;

@interface ImageHolderView : UIView<UIScrollViewDelegate,UITextFieldDelegate>
@property (nonatomic, retain) RCImage *image;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UITextField *nameField;
@property (nonatomic, retain) id delegate;

-(IBAction)doActionMenu:(id)sender;
@end


@protocol ImageHolderViewDelegate<NSObject>
-(void)showActionMenuForImage:(RCImage*)img button:(UIButton*)button;
@end
