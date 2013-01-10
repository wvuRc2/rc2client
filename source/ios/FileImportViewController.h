//
//  FileImportViewController.h
//  Rc2Client
//
//  Created by Mark Lilback on 1/9/13.
//  Copyright (c) 2013 West Virginia University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileImportViewController : UIViewController
@property (nonatomic, copy) NSURL *inputUrl;
@property (nonatomic, copy) BasicBlock cleanupBlock;
@end
