//
//  ImageHolderView.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "ImageHolderView.h"
#import "RCImage.h"

static const CGFloat kKeyAnimationDuration = 0.3;
static const CGFloat kMinScrollFraction = 0.2;
static const CGFloat kMaxScrollFraction = 0.8;
static const CGFloat kKeyboardHeight = 354;

@interface ImageHolderView() {
	CGFloat _animationDistance;
}
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *nameLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation ImageHolderView
-(void)awakeFromNib
{
	CGRect frame = self.frame;
	frame.origin = CGPointZero;
	frame.size.height -= 40;
	frame.size.width -= 40;
	frame.origin.y = 40;
	frame.origin.x = 20;
	UIScrollView *sv = [[UIScrollView alloc] initWithFrame:frame];
	self.scrollView = sv;
	[self addSubview:sv];
	sv.delegate = self;
	sv.minimumZoomScale = 0.25;
	sv.maximumZoomScale = 4.0;
	sv.showsHorizontalScrollIndicator=NO;
	sv.showsVerticalScrollIndicator=NO;
	sv.contentMode=UIViewContentModeCenter;
	sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
	[sv addSubview:iv];
	self.imageView = iv;
	iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	iv.contentMode=UIViewContentModeCenter;

	CGRect barRect = self.bounds;
	barRect.size.height = 38;
	UIView *bv = [[UIView alloc] initWithFrame:barRect];
	[self addSubview:bv];
	self.barView = bv;
	bv.backgroundColor = [UIColor blackColor];
	bv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	UIButton *nf = [UIButton buttonWithType:UIButtonTypeCustom];
	nf.frame = CGRectMake((barRect.size.width - 200)/2, 4, 200, 32);
	self.nameLabel = nf;
	nf.titleLabel.textAlignment = NSTextAlignmentCenter;
	nf.titleLabel.textColor = [UIColor whiteColor];
	nf.opaque = NO;
	nf.backgroundColor = [UIColor clearColor];
	[nf addTarget:self action:@selector(showImageSwitcher:) forControlEvents:UIControlEventTouchUpInside];
	[bv addSubview:nf];

	self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 16, 80, 20)];
	[bv addSubview:self.dateLabel];
	self.dateLabel.textColor = [UIColor whiteColor];
	self.dateLabel.opaque=NO;
	self.dateLabel.font = [UIFont italicSystemFontOfSize:10.0];
	self.dateLabel.backgroundColor = [UIColor clearColor];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	CGRect btnFrame = CGRectMake(CGRectGetMaxX(bv.bounds)-31, 8, 23, 17);
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	self.actionButton = btn;
	[bv addSubview:btn];
	btn.frame = btnFrame;
	btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[btn setImage:[UIImage imageNamed:@"action"] forState:UIControlStateNormal];
	[btn addTarget: self action:@selector(doActionMenu:) forControlEvents:UIControlEventTouchUpInside];
	
	self.layer.borderColor = [UIColor blackColor].CGColor;
	self.layer.borderWidth = 1.0;
}

-(void)adjustImageDetails
{
	UIImage *img = self.imageView.image;
	CGSize sz = img.size;
	if (self.scrollView.frame.size.width > sz.width)
		sz.width = self.scrollView.frame.size.width;
	if (self.scrollView.frame.size.height > sz.height)
		sz.height = self.scrollView.frame.size.height;
	self.scrollView.contentSize = sz;
	self.scrollView.minimumZoomScale = self.scrollView.frame.size.width / img.size.width;
//	self.scrollView.zoomScale = fmin(self.scrollView.minimumZoomScale, 1.0);
}

-(IBAction)showImageSwitcher:(id)sender
{
	CGRect r = [self convertRect:self.nameLabel.frame fromView:self.nameLabel];
	[self.delegate showImageSwitcher:self forRect:r];
}

-(IBAction)doActionMenu:(id)sender
{
	[self.delegate showActionMenuForImage:self.image button:sender];
}

-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self adjustImageDetails];
	CGRect f = self.nameLabel.frame;
	f.origin.x = floor((self.barView.frame.size.width - f.size.width)/2);
	self.nameLabel.frame = f;
}

-(CGRect)centeredFrameForScrollView:(UIScrollView*)scroll andView:(UIView*)view
{
	CGSize bndsSize = scroll.bounds.size;
	CGRect frameToCenter = view.frame;
	if (frameToCenter.size.width < bndsSize.width)
		frameToCenter.origin.x = (bndsSize.width - frameToCenter.size.width) / 2;
	else
		frameToCenter.origin.x = 0;
	if (frameToCenter.size.height < bndsSize.height)
		frameToCenter.origin.y = (bndsSize.height - frameToCenter.size.height) / 2;
	else
		frameToCenter.origin.y = 0;
	return frameToCenter;
}

-(void)scrollViewDidZoom:(UIScrollView*)scroll
{
	CGRect ourBnds = self.scrollView.bounds;
	CGRect maxBnds = CGRectInset(ourBnds, floor(ourBnds.size.width/2), floor(ourBnds.size.height/2));
	CGRect suggestedBnds = [self centeredFrameForScrollView:scroll andView:self.imageView];
	if (CGRectContainsRect(maxBnds, suggestedBnds)) {
		if ((ourBnds.size.width > suggestedBnds.size.width)) {
			//we want to center suggestedBnds inside ourBnds
			suggestedBnds.origin.x = floor((ourBnds.size.width - suggestedBnds.size.width)/2);
			suggestedBnds.origin.y = floor((ourBnds.size.height - suggestedBnds.size.height)/2);
		}
		self.imageView.bounds = suggestedBnds;
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scroll withView:(UIView *)view atScale:(float)scale
{
	CGRect ourBnds = self.scrollView.bounds;
	CGRect suggestedBnds = [self centeredFrameForScrollView:scroll andView:self.imageView];
	if ((suggestedBnds.size.width < ourBnds.size.width) && (suggestedBnds.size.height < ourBnds.size.height)) {
		//we want to center the view
		suggestedBnds.origin.x = floor((ourBnds.size.width - suggestedBnds.size.width)/2);
		suggestedBnds.origin.y = floor((ourBnds.size.height - suggestedBnds.size.height)/2);
		self.imageView.bounds = suggestedBnds;
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return self.imageView;
}

-(void)setImage:(RCImage *)img
{
	if (img == _image)
		return;
	_image = img;
	[img image];
	self.imageView.image = img.image;
	[self.nameLabel setTitle:[img.name stringByDeletingPathExtension] forState:UIControlStateNormal];
	self.dateLabel.text = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:img.timestamp]];
	[self adjustImageDetails];
	RunAfterDelay(0.3, ^{
		_imageView.image = img.image;
	});
}

@end
