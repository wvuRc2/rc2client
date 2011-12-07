//
//  FileDetailsCell.m
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import "FileDetailsCell.h"
#import "RCFile.h"

@implementation FileDetailsCell
@synthesize nameLabel;
@synthesize sizeLabel;
@synthesize imgView;
@synthesize lastModLabel;
@synthesize localLastModLabel;
@synthesize dateFormatter;

-(void)dealloc
{
	self.dateFormatter=nil;
	[super dealloc];
}

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

	NSString *imgName = @"doc";
	if ([file.name hasSuffix:@".R"])
		imgName = @"RDoc";
	else if ([file.name hasSuffix:@".Rnw"])
		imgName = @"RnWDoc";
	else if ([file.name hasSuffix:@".pdf"])
		imgName = @"console/pdf";
	self.imgView.image = [UIImage imageNamed:imgName];
}

@end
