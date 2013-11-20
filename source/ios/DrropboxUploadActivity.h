//
//  DrropboxUploadActivity.h
//  Rc2Client
//
//  Created by Mark Lilback on 11/20/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrropboxUploadActivity : UIActivity
@property (nonatomic, copy) NSArray *filesToUpload; //RCFile instances
@property (nonatomic, copy) BasicBlock performBlock;
@end
