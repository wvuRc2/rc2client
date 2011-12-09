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
@property (nonatomic, strong) RCImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) id delegate;

-(IBAction)doActionMenu:(id)sender;
@end


@protocol ImageHolderViewDelegate<NSObject>
-(void)showActionMenuForImage:(RCImage*)img button:(UIButton*)button;
@end
