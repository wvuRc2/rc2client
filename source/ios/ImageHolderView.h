//
//  ImageHolderView.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

@protocol ImageHolderViewDelegate;
@class RCImage;

@interface ImageHolderView : UIView<UIScrollViewDelegate>
@property (nonatomic, strong) RCImage *image;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) id delegate;

-(IBAction)doActionMenu:(id)sender;
@end


@protocol ImageHolderViewDelegate<NSObject>
-(void)showActionMenuForImage:(RCImage*)img button:(UIButton*)button;
-(void)showImageSwitcher:(ImageHolderView*)imgView forRect:(CGRect)rect;
@end
