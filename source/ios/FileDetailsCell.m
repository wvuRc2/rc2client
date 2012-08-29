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
@synthesize nameLabel;
@synthesize sizeLabel;
@synthesize imgView;
@synthesize lastModLabel;
@synthesize localLastModLabel;
@synthesize dateFormatter;
@synthesize permissionView;

-(CGFloat)rowHeight
{
	return 96.0;
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
	if (file.localLastModified)
		self.localLastModLabel.text = [self.dateFormatter stringFromDate:file.localLastModified];
	else
		self.localLastModLabel.text = @"-";

	self.imgView.image = file.fileType.image;
	self.permissionView.image = file.permissionImage;
}

@end
