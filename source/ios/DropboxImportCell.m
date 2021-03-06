//
//  DropboxImportCell.m
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//

#import "DropboxImportCell.h"

@implementation DropboxImportCell

- (void)awakeFromNib
{
	[self.importButton removeFromSuperview];
	[self.statusImage removeFromSuperview];
}

-(void)treatAsDirectory
{
	self.textLabel.enabled = YES;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	self.selectionStyle = UITableViewCellSelectionStyleBlue;
	self.accessoryView = nil;
}

-(void)treatAsUnsupported
{
	self.textLabel.enabled = NO;
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	self.accessoryView = nil;
}

-(void)treatAsImportable
{
	self.textLabel.enabled = YES;
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	self.accessoryView = self.importButton;
}
-(void)treatAsImported
{
	self.textLabel.enabled = YES;
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	self.accessoryView = self.statusImage;
}

@end
