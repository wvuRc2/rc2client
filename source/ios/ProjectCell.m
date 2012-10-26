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
@end

@implementation ProjectCell

-(id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self = [[NSBundle mainBundle] loadNibNamed:@"ProjectCell" owner:nil options:nil].firstObject;
	}
	return self;
}

-(void)setProject:(RCProject *)project
{
	_project = project;
	self.nameLabel.text = project.name;
}
@end
