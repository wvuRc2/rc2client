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

@interface FileDetailsCell()
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *sizeLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastModLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imgView;
@property (nonatomic, weak) IBOutlet UIImageView *permissionView;;
@end

@implementation FileDetailsCell

-(void)showValuesForFile:(RCFile*)file
{
	self.nameLabel.text = file.name;
	self.sizeLabel.text = file.sizeString;
	self.lastModLabel.text = [self.dateFormatter stringFromDate:file.lastModified];

	self.imgView.image = file.fileType.image;
	self.permissionView.image = file.permissionImage;
}

@end
