//
//  RCMImageDetailController.h
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RCImage;

@interface RCMImageDetailController : AMViewController
@property (nonatomic, strong) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) IBOutlet NSPopUpButton *filePopUp;
@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) NSArray *availableImages;
@property (nonatomic, strong) RCImage *selectedImage;
@end