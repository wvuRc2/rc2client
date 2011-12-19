//
//  RCMMultiImageController.h
//  MacClient
//
//  Created by Mark Lilback on 12/16/11.
//  Copyright (c) 2011 Agile Monks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MacClientAbstractViewController.h"

@class RCMImageDetailController;

@interface RCMMultiImageController : MacClientAbstractViewController
@property (nonatomic, strong) IBOutlet NSView *frame1;
@property (nonatomic, strong) IBOutlet NSView *frame2;
@property (nonatomic, strong) IBOutlet NSView *frame3;
@property (nonatomic, strong) IBOutlet NSView *frame4;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView1;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView2;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView3;
@property (nonatomic, strong) IBOutlet RCMImageDetailController *imageView4;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *layoutControl;
@property (nonatomic, strong) NSArray *availableImages;
@property (nonatomic) NSInteger numberImagesVisible;

-(void)setDisplayedImages:(NSArray*)imgs;
@end
