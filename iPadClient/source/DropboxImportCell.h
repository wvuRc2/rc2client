//
//  DropboxImportCell.h
//  iPadClient
//
//  Created by Mark Lilback on 9/3/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//


@interface DropboxImportCell : iAMTableViewCell
@property (nonatomic, retain) IBOutlet UIButton *importButton;
@property (nonatomic, retain) IBOutlet UIImageView *statusImage;
@property (nonatomic, retain) IBOutlet UILabel *textLabel;

-(void)treatAsDirectory;
-(void)treatAsUnsupported;
-(void)treatAsImportable;
-(void)treatAsImported;
@end
