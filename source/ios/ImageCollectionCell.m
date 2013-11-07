//
//  ImageCollectionCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/2/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import "ImageCollectionCell.h"
#import "RCImage.h"

@interface ImageCollectionCell ()
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *barView;
@property (nonatomic, strong) IBOutlet UIButton *actionButton;
@property (nonatomic, strong) IBOutlet UIButton *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dateLabelWidthConstraint;

@end

@implementation ImageCollectionCell

-(void)awakeFromNib
{
	[self setupValues];
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
	self.contentView.layer.backgroundColor = self.barView.backgroundColor.CGColor;
	self.contentView.layer.filters = @[filter];
	self.backgroundView.backgroundColor = self.barView.backgroundColor;
}

-(void)setupValues
{
	static __strong NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	});
	self.actionButton.hidden = _image == nil;
	if (nil == _image) {
		UIFontDescriptor *fontD = [self.nameLabel.titleLabel.font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorTraitsAttribute:@{UIFontSymbolicTrait:@(UIFontDescriptorTraitItalic)}}];
		UIFont *fnt = [UIFont fontWithDescriptor:fontD size:12];
		[self.nameLabel setAttributedTitle:[[NSAttributedString alloc] initWithString:@"tap to select image" attributes:@{NSFontAttributeName:fnt}] forState:UIControlStateNormal];
		self.dateLabel.text = @"";
		self.dateLabelWidthConstraint.constant = 40;
	} else {
		NSAttributedString *astr = [[NSAttributedString alloc] initWithString:[_image.name stringByDeletingPathExtension]];
		[self.nameLabel setAttributedTitle:astr forState:UIControlStateNormal];
		self.dateLabelWidthConstraint.constant = 100;
		self.dateLabel.text = [dateFormatter stringFromDate:self.image.timestamp];
	}
	[self.nameLabel setTitle:_image.name forState:UIControlStateNormal];
	self.imageView.image = self.image.image;
}

-(IBAction)selectImage:(id)sender
{
	[self.imageDelegate imageCollectionCell:self selectImageFrom:[self convertRect:[sender frame] fromView:sender]];
}

-(IBAction)showActivities:(id)sender
{
	//convert rect from barview to cell
	CGRect r = self.actionButton.frame;
	r = [self convertRect:r fromView:self.actionButton.superview];
	[self.imageDelegate imageCollectionCell:self showActionsFromRect:r];
}

-(void)setImage:(RCImage *)image
{
	_image = image;
	[self setupValues];
}
@end
