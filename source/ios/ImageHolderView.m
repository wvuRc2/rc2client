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
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelWidthConstraint;
@property (nonatomic, weak) CALayer *blayer;
@end

@implementation ImageHolderView
-(void)awakeFromNib
{
	[[NSBundle mainBundle] loadNibNamed:@"ImageHolderView" owner:self options:nil];
	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.contentView];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_contentView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_contentView)]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_contentView]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_contentView)]];
	self.scrollView.minimumZoomScale = 0.25;
	self.scrollView.maximumZoomScale = 4.0;
	self.actionButton.tintColor = self.tintColor;
	UIImage *actionImg = [[UIImage imageNamed:@"action"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[self.actionButton setImage:actionImg forState:UIControlStateNormal];
	//make date label italic
	UIFontDescriptor *fontD = [self.dateLabel.font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontSymbolicTrait:@(UIFontDescriptorTraitItalic)}}];
	self.dateLabel.font = [UIFont fontWithDescriptor:fontD size:self.dateLabel.font.pointSize];

	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

	self.barView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
	CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
	self.barView.layer.filters = @[filter];
	self.layer.backgroundColor = self.barView.backgroundColor.CGColor;
	self.layer.filters = @[filter];
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
	static __strong NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	});
	self.actionButton.hidden = img == nil;
	if (img && img == _image)
		return;
	_image = img;
	[img image];
	self.imageView.image = img.image;
	if (nil == img) {
		UIFontDescriptor *fontD = [self.nameLabel.titleLabel.font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontSymbolicTrait:@(UIFontDescriptorTraitItalic)}}];
		UIFont *fnt = [UIFont fontWithDescriptor:fontD size:12];
		[self.nameLabel setAttributedTitle:[[NSAttributedString alloc] initWithString:@"tap to select image" attributes:@{NSFontAttributeName:fnt}] forState:UIControlStateNormal];
		self.dateLabel.text = @"";
		self.dateLabelWidthConstraint.constant = 40;
	} else {
		NSAttributedString *astr = [[NSAttributedString alloc] initWithString:[img.name stringByDeletingPathExtension]];
		[self.nameLabel setAttributedTitle:astr forState:UIControlStateNormal];
		self.dateLabelWidthConstraint.constant = 100;
		self.dateLabel.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:img.timestamp]];
	}
	[self adjustImageDetails];
	RunAfterDelay(0.3, ^{
		_imageView.image = img.image;
	});
}

@end
