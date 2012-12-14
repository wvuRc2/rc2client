//
//  FileDetailsCell.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import "FileDetailsCell.h"
#import "RCFile.h"
#import "Rc2FileType.h"

@implementation FileDetailsCell

-(CGFloat)rowHeight
{
	return 60.0;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
}

-(void)showValuesForFile:(RCFile*)file
{
	self.nameLabel.text = file.name;
	self.sizeLabel.text = file.sizeString;
	self.lastModLabel.text = [self.dateFormatter stringFromDate:file.lastModified];

	self.imgView.image = file.fileType.image;
	self.permissionView.image = file.permissionImage;
}

@end
