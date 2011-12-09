//
//  FileDetailsCell.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 Agile Monks. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;

@interface FileDetailsCell : iAMTableViewCell
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *sizeLabel;
@property (nonatomic, strong) IBOutlet UILabel *lastModLabel;
@property (nonatomic, strong) IBOutlet UILabel *localLastModLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imgView;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

-(void)showValuesForFile:(RCFile*)file;
@end
