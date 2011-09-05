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
@property (nonatomic, assign) IBOutlet UILabel *nameLabel;
@property (nonatomic, assign) IBOutlet UILabel *sizeLabel;
@property (nonatomic, assign) IBOutlet UILabel *lastModLabel;
@property (nonatomic, assign) IBOutlet UILabel *localLastModLabel;
@property (nonatomic, assign) IBOutlet UIImageView *imgView;

@property (nonatomic, retain) NSDateFormatter *dateFormatter;

-(void)showValuesForFile:(RCFile*)file;
@end
