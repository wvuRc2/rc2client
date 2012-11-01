//
//  ProjectCell.m
//  Rc2Client
//
//  Created by Mark Lilback on 10/26/12.
//  Copyright (c) 2012 West Virginia University. All rights reserved.
//

#import "ProjectCell.h"
#import "RCProject.h"

@interface ProjectCell ()
@property (weak) IBOutlet UILabel *nameLabel;
@property (weak) IBOutlet UIImageView *imageView;
@property (strong) IBOutlet UIView *myView;
@end

@implementation ProjectCell

-(id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self = [[NSBundle mainBundle] loadNibNamed:@"ProjectCell" owner:nil options:nil].firstObject;
		CALayer *layer = self.layer;
		layer.cornerRadius = 8.0;
		self.backgroundColor = [UIColor clearColor];
		
		layer = [CALayer layer];
		layer.frame = CGRectInset(self.frame, 10, 10);
		layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
		layer.shadowOpacity = 0.8;
		layer.shadowOffset = CGSizeMake(4, -4);
		layer.shadowRadius = 2;
		layer.cornerRadius = 13.0;
		layer.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.2].CGColor;
		self.contentView.backgroundColor = [UIColor clearColor];
		[self.contentView.layer addSublayer:layer];

		self.backgroundView.backgroundColor = [UIColor clearColor];
	}
	return self;
}

-(void)setProject:(RCProject *)project
{
	_project = project;
	self.nameLabel.text = project.name;
}

-(void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	self.backgroundColor = highlighted ? [[UIColor blueColor] colorWithAlphaComponent:0.3] : [UIColor clearColor];
}

@end
