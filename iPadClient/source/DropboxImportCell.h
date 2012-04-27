//
//  DropboxImportCell.h
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 West Virginia University. All rights reserved.
//


@interface DropboxImportCell : iAMTableViewCell
@property (nonatomic, strong) IBOutlet UIButton *importButton;
@property (nonatomic, strong) IBOutlet UIImageView *statusImage;
@property (nonatomic, strong) IBOutlet UILabel *textLabel;

-(void)treatAsDirectory;
-(void)treatAsUnsupported;
-(void)treatAsImportable;
-(void)treatAsImported;
@end
