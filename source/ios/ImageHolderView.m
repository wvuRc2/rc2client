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
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIView *barView;
@property (nonatomic, strong) IBOutlet UIButton *actionButton;
@property (nonatomic, strong) IBOutlet UIButton *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIToolbar *victimToolbar;
@property (nonatomic, weak) CALayer *blayer;
@end

@implementation ImageHolderView
-(void)awakeFromNib
{
	[[NSBundle mainBundle] loadNibNamed:@"ImageHolderView" owner:self options:nil];
	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
//	self.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.contentView];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_contentView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_contentView)]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_contentView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_contentView)]];
	self.scrollView.minimumZoomScale = 0.25;
	self.scrollView.maximumZoomScale = 4.0;
	self.actionButton.tintColor = self.tintColor;
	UIImage *actionImg = [[UIImage imageNamed:@"action"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[self.actionButton setImage:actionImg forState:UIControlStateNormal];
	self.dateLabel.backgroundColor = [UIColor orangeColor];
	self.dateLabel.opaque = YES;
/*	CGRect frame = self.frame;
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
	iv.frame = sv.bounds;
//	[sv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[iv]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(iv)]];
//	[sv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[iv]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(iv)]];
	iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	iv.contentMode=UIViewContentModeCenter;


	self.victimToolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
	CALayer *blayer =  self.victimToolbar.layer;
	self.blayer = blayer;
	CGRect barRect = self.bounds;
	barRect.size.height = 38;
	UIView *bv = [[UIView alloc] initWithFrame:barRect];
//	[self insertSubview:bv belowSubview:self.imageView];
	self.barView = bv;
	bv.layer.borderWidth = 2;
	bv.layer.borderColor = [UIColor yellowColor].CGColor;
	bv.layer.masksToBounds = YES;
	bv.backgroundColor = [UIColor blackColor];
//	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bv]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bv)]];
//	bv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	UIButton *nf = [UIButton buttonWithType:UIButtonTypeCustom];
	nf.frame = CGRectMake((barRect.size.width - 200)/2, 4, 200, 32);
	self.nameLabel = nf;
	nf.titleLabel.textAlignment = NSTextAlignmentCenter;
//	nf.titleLabel.textColor = [UIColor whiteColor];
	nf.tintColor = self.tintColor;
	nf.translatesAutoresizingMaskIntoConstraints = NO;
	nf.opaque = NO;
	nf.backgroundColor = [UIColor clearColor];
	[nf addTarget:self action:@selector(showImageSwitcher:) forControlEvents:UIControlEventTouchUpInside];
	[bv addSubview:nf];

	self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 16, 100, 20)];
	[bv addSubview:self.dateLabel];
	self.dateLabel.opaque=NO;
	self.dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	self.dateLabel.backgroundColor = [UIColor clearColor];
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	self.dateLabel.layer.borderColor = [UIColor redColor].CGColor;
	self.dateLabel.layer.borderWidth = 2;
	self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
//	[bv addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bv attribute:NSLayoutAttributeBottom multiplier:1 constant:-2]];
	[bv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_dateLabel]-2-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_dateLabel)]];
	CGRect btnFrame = CGRectMake(CGRectGetMaxX(bv.bounds)-31, 8, 23, 17);
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	self.actionButton = btn;
	[bv addSubview:btn];
	btn.frame = btnFrame;
//	btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	btn.translatesAutoresizingMaskIntoConstraints = NO;
	[btn setImage:[UIImage imageNamed:@"action"] forState:UIControlStateNormal];
	[btn addTarget: self action:@selector(doActionMenu:) forControlEvents:UIControlEventTouchUpInside];
	[bv addConstraint:[NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:bv attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
	
	[bv.layer insertSublayer:blayer atIndex:0];
	self.layer.borderColor = [UIColor blackColor].CGColor;
	self.layer.borderWidth = 1.0;

	bv.translatesAutoresizingMaskIntoConstraints = NO;
	[bv addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_dateLabel(100)]-2-[_nameLabel(>=40)]-2-[_actionButton]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_dateLabel,_nameLabel,_actionButton)]];
*/
//	NSDictionary *vdict = NSDictionaryOfVariableBindings(_imageView);
//	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView(width)]|" options:0 metrics:@{@"width": @(_imageView.image.size.width)} views:vdict]];
//	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView(height)]|" options:0 metrics:@{@"height": @(_imageView.image.size.height)} views:vdict]];
	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.layer.borderWidth = 2;
	self.layer.borderColor = [UIColor blueColor].CGColor;
	self.barView.layer.borderColor = [UIColor yellowColor].CGColor;
	self.barView.layer.borderWidth = 2;
	self.imageView.layer. borderWidth = 2;
	self.imageView.layer.borderColor = [UIColor redColor].CGColor;
	self.scrollView.layer.borderColor = [UIColor greenColor].CGColor;
	self.scrollView.layer.borderWidth = 2;
}

-(void)didMoveToWindow
{
	[super didMoveToWindow];
	self.scrollView.contentOffset = CGPointZero;
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
	self.blayer.frame = self.bounds;
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
	CGRect imframe = self.imageView.frame;
	imframe.origin = CGPointZero;
	self.imageView.frame = imframe;
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
	return nil;//self.imageView;
}

-(void)setImage:(RCImage *)img
{
	static NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	});
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
