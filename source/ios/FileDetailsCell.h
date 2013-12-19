//
//  FileDetailsCell.h
//  iPadClient
//
//  Created by Mark Lilback on 8/25/11.
//  Copyright 2011 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCFile;

@interface FileDetailsCell : UITableViewCell
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

-(void)showValuesForFile:(RCFile*)file;
-(void)showValuesForFile:(RCFile*)file snippet:(NSAttributedString*)snippet;
@end
